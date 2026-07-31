#!/bin/bash

#SBATCH --job-name=bt2_backmap
#SBATCH --output=%x_%A_%a.out
#SBATCH --error=%x_%A_%a.err
#SBATCH --time=24:00:00
#SBATCH --array=0-65
#SBATCH --cpus-per-task=8
#SBATCH --mem=100G

date

# Load the required modules for bowtie2 and samtools
module load StdEnv/2023 bowtie2/2.5.4 samtools/1.22.1 python/3.11.5
echo "Modules loaded"

# These are the directory variables for samples (containing raw reads) and the newly created output
SAMPLE_DIR=$SCRATCH/RP01-93_CC_CT/RP01-93_CC_CT_fastp_bt2_out/bt2_out
OUT_DIR=$SCRATCH/RP01-93_CC_CT/RP01-93_CC_CT_analysis

# Create output directory that will contain all sample IDs
BT2_BACKMAP_OUT=$OUT_DIR/bt2_backmap_out
mkdir -p $BT2_BACKMAP_OUT

# Build array of directories - all directories have the same sample ID (e.g. 021_V1) as each read set
DIRS=(${SAMPLE_DIR}/*/)
READ_DIR=${DIRS[$SLURM_ARRAY_TASK_ID]} # Uses the array index to go through each sample ID
SAMPLE_ID=$(basename "${READ_DIR}")
P_ID=$(basename ${READ_DIR%_*}) # Extract the patient ID (before the underscore) from the sample ID

R1=$(ls ${READ_DIR}*unaligned_R1*.fastq.gz)
R2=$(ls ${READ_DIR}*unaligned_R2*.fastq.gz)

# Get the corresponding megahit co-assemblies 
ASSEMBLY=$OUT_DIR/megahit_co_assembly_out/${P_ID}/${P_ID}_final.contigs.fa

# Print out the inputs for bowtie2
echo "Sample: $SAMPLE_ID"
echo "R1: $R1"
echo "R2: $R2"
echo "Patient: $P_ID"
echo "Megahit co-assembly path: $ASSEMBLY"

# Create a sample ID specific output directory in BT2_BACKMAP_OUT
BT2_SAMPLE_ID=$BT2_BACKMAP_OUT/${SAMPLE_ID}
mkdir -p $BT2_SAMPLE_ID

# Build a bowtie2 index using the prodigal output from the megahit co-assembly for each patient ID (e.g. 021)
cd $BT2_SAMPLE_ID # Go to the output folder for this sample ID

if [ ! -e "index_${P_ID}.1.bt2" ] && [ ! -e "index_${P_ID}.1.bt2l" ]; then
	echo "Bowtie2 index not found. Building now for $P_ID"
	bowtie2-build $ASSEMBLY index_${P_ID}
	echo "==============================="
	ls
fi

cd ..

# Map the R1 and R2 reads to the newly created bowtie2 index
bowtie2 -x $BT2_SAMPLE_ID/"index_${P_ID}" \
--fr --quiet \
-p $SLURM_CPUS_PER_TASK \
-1 $R1 \
-2 $R2 \
-S $BT2_SAMPLE_ID/${SAMPLE_ID}_bt2_backmap.sam \
2> $BT2_SAMPLE_ID/${SAMPLE_ID}_bt2_backmap.log

# Define bt2 output as variables
SAM=$BT2_SAMPLE_ID/${SAMPLE_ID}_bt2_backmap.sam
BAM=$BT2_SAMPLE_ID/${SAMPLE_ID}_bt2_backmap.bam

# Convert SAM to BAM
samtools view -bS "${SAM}" > "${BAM}"
# Sort the BAM
samtools sort -@ $SLURM_CPUS_PER_TASK "${BAM}" -o "$BT2_SAMPLE_ID/${SAMPLE_ID}_bt2_backmap_sorted.bam"
# Create an index of the sorted BAM
samtools index $BT2_SAMPLE_ID/${SAMPLE_ID}_bt2_backmap_sorted.bam
# Remove the SAM file
rm $SAM
echo "Finished mapping with bowtie2. BAM output: $BT2_SAMPLE_ID/${SAMPLE_ID}_bt2_backmap_sorted.bam"
