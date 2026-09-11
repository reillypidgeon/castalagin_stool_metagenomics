#!/usr/bin/env bash

#SBATCH --job-name=bt2_backmap
#SBATCH --output=%x_%A_%a.out
#SBATCH --error=%x_%A_%a.err
#SBATCH --time=24:00:00
#SBATCH --array=0-65
#SBATCH --cpus-per-task=8
#SBATCH --mem=100G

set -euo pipefail

# Define common variables
#===========================================================================
project_dir="$SCRATCH/PRJEB76307_MGX"
sample_dir="${project_dir}/fastp_bt2_qc/bt2_out" # This directory contains 66 sample directories containing paired-end reads R1 and R2 (after removing reads mapped to the human genome
scripts_dir="$SCRATCH/castalagin_stool_metagenomics/PRJEB76307_metagenomics" # Scripts from repository
megahit_dir="${project_dir}/megahit_co_out"

# Create output directory
bt2_backmap_dir="${project_dir}/bt2_backmap_out"
mkdir -p "${bt2_backmap_dir}"
#===========================================================================

# Build array of directories to extract sample_id, subject_id, and read paths
#===========================================================================
dirs=(${sample_dir}/*/)
read_dir=${dirs[${SLURM_ARRAY_TASK_ID}]}
sample_id=$(basename "${read_dir}")
subject_id=$(basename ${read_dir%_*}) # Extracts before the underscore

# Define read paths
R1=$(ls ${read_dir}*unaligned_R1*.fastq.gz)
R2=$(ls ${read_dir}*unaligned_R2*.fastq.gz)

# Define the corresponding megahit co-assemblies 
assembly="${megahit_dir}/${subject_id}/${subject_id}_final.contigs.fa"

# Print out the inputs for bowtie2
echo "Sample: $SAMPLE_ID"
echo "R1: $R1"
echo "R2: $R2"
echo "Subject: $subject_id"
echo "Megahit co-assembly path: $assembly"

# Create a sample ID specific output directory in BT2_BACKMAP_OUT
BT2_SAMPLE_ID=$BT2_BACKMAP_OUT/${SAMPLE_ID}
mkdir -p $BT2_SAMPLE_ID






# Load the required modules for bowtie2 and samtools
module load StdEnv/2023 bowtie2/2.5.4 samtools/1.22.1 python/3.11.5
echo "Modules loaded"

# Build a bowtie2 index using the prodigal output from the megahit co-assembly for each patient ID (e.g. 021)
cd $BT2_SAMPLE_ID # Go to the output folder for this sample ID

if [ ! -e "index_${subject_id}.1.bt2" ] && [ ! -e "index_${subject_id}.1.bt2l" ]; then
	echo "Bowtie2 index not found. Building now for $subject_id"
	bowtie2-build $assembly index_${subject_id}
	echo "==============================="
	ls
fi

cd ..

# Map the R1 and R2 reads to the newly created bowtie2 index
bowtie2 -x $BT2_SAMPLE_ID/"index_${subject_id}" \
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
