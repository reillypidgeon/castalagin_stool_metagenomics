#!/usr/bin/env bash

#SBATCH --job-name=megahit_prodigal
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
#SBATCH --time=20:00:00
#SBATCH --cpus-per-task=12
#SBATCH --mem=120G

set -euo pipefail

# Define variables
#============================================================================
project_dir="$SCRATCH/PRJNA1499868_MGX"
read_dir="${project_dir}/fastp_bt2_qc/bt2_out/" # Using the trimmed, unaligned reads
sample_id="MO67"
R1="${read_dir}/${sample_id}_bt2_t2t_unaligned_R1.fastq.gz"
R2="${read_dir}/${sample_id}_bt2_t2t_unaligned_R2.fastq.gz"

# DO NOT create a new directory for megahit
# It will create one in the --out-dir portion and cannot already exist
megahit_dir="${project_dir}/megahit_out"
#============================================================================

# Load the required modules
module load megahit/1.2.9 StdEnv/2023

# Run megahit
megahit -1 $R1 -2 $R2 \
--presets meta-sensitive \
--continue \
--min-contig-len 500 \
-t ${SLURM_CPUS_PER_TASK} \
--out-dir "${megahit_dir}"

# Rename megahit output
mv "${megahit_dir}/final.contigs.fa" "${megahit_dir}/${sample_id}_final.contigs.fa"

echo "Finished running megahit"

echo "Starting prodigal workflow from megahit assembly"

# Load required modules for prodigal
module load prodigal/2.6.3

# Define variables for the input and output directories
#============================================================================
# Output from megahit becomes input for prodigal
prodigal_dir="${project_dir}/prodigal_out"
mkdir -p "${prodigal_dir}"
#============================================================================

# Run prodigal on the contigs
# Uses the Standard Bacteria/Archaea translation table (11)
prodigal -i "${megahit_dir}/${sample_id}_final.contigs.fa" \
-p meta \
-g 11 \
-a "${prodigal_dir}/${sample_id}_prodigal_proteins.faa" \
-d "${prodigal_dir}/${sample_id}_prodigal_genes.fna" \
-o "${prodigal_dir}/${sample_id}_prodigal_annotations.gff"

echo "Finished running prodigal on sample ${sample_id}"
