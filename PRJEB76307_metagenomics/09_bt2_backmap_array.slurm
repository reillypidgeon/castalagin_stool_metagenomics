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
sample_dir="${project_dir}/fastp_bt2_qc/bt2_out" # This directory contains 66 sample directories containing paired-end reads R1 and R2 (after removing reads mapped to the human genome)
scripts_dir="$SCRATCH/castalagin_stool_metagenomics/PRJEB76307_metagenomics" # Scripts from repository
megahit_dir="${project_dir}/megahit_co_out" # Contains contigs from the assembly step

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

# Create a sub-directory for the bt2 output
bt2_sample_id_dir="$bt2_backmap_dir/${sample_id}"
mkdir -p "${bt2_sample_id_dir}"
#===========================================================================

# Print out the inputs for bowtie2
echo "Sample: ${sample_id}"
echo "Subject: ${subject_id}"
echo "R1: $R1"
echo "R2: $R2"
echo "Megahit co-assembly path: $assembly"

# Load modules
module load StdEnv/2023 bowtie2/2.5.4 samtools/1.22.1 python/3.11.5 # Required by bowtie2/2.5.4
echo "Modules loaded"

# Build a bowtie2 index using the megahit co-assembly for each subject_id
if [[ ! -e "${bt2_sample_id_dir}/index_${subject_id}.1.bt2" ]] && 
    [[ ! -e "${bt2_sample_id_dir}/index_${subject_id}.1.bt2l" ]]; then
    echo "Bowtie2 index for ${subject_id} not found"
    echo "Building one from $assembly"
    bowtie2-build "$assembly" "${bt2_sample_id_dir}/index_${subject_id}"
else
    echo "Bowtie2 index already exists"
    ls "${bt2_sample_id_dir}"
fi

# Define bt2 output as variable
bt2_output_prefix="${bt2_sample_id_dir}/${sample_id}_bt2_backmap"

# Map the R1 and R2 reads to the bowtie2 index
bowtie2 -x "${bt2_sample_id_dir}/index_${subject_id}" \
--fr --quiet \
-p ${SLURM_CPUS_PER_TASK} \
-1 $R1 \
-2 $R2 \
-S "${bt2_output_prefix}.sam" \
2> "${bt2_output_prefix}.log"

# Convert SAM to BAM
samtools view -bS "${bt2_output_prefix}.sam" > "${bt2_output_prefix}.bam"

# Sort the BAM
samtools sort -@ ${SLURM_CPUS_PER_TASK} "${bt2_output_prefix}.bam" -o "${bt2_output_prefix}_sorted.bam"

# Create an index of the sorted BAM
samtools index "${bt2_output_prefix}_sorted.bam"

# Remove the SAM file
rm "${bt2_output_prefix}.sam"

echo "Finished mapping with bowtie2. BAM output: ${bt2_output_prefix}_sorted.bam"
