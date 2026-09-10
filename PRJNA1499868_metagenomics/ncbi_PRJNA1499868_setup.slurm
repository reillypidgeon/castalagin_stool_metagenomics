#!/usr/bin/env bash

#SBATCH --job-name=PRJNA1499868_setup
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
#SBATCH --time=00:15:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G

set -euo pipefail

# Define variables
#===========================================================================
accession="$1"
read_dir="$2"
sample_id="$3"
sra_dir="${read_dir}/$accession"

# Create a temporary directory
tmp="${SLURM_TMPDIR}/sra_tmp"
mkdir -p "$tmp"
#===========================================================================

# Extract the reads from the prefetched SRA data
module load sra-toolkit

echo "Starting FASTQ extraction for ${accession}"

fasterq-dump \
    "${sra_dir}" \
    --split-files \
    --threads "${SLURM_CPUS_PER_TASK}" \
    --temp "$tmp" \
    --outdir "${read_dir}"

rm -r ${sra_dir}

echo "Compressing FASTQ files"

gzip -v "${read_dir}/${accession}_1.fastq"
gzip -v "${read_dir}/${accession}_2.fastq"

echo "Finished zipping FASTQ files"

# Rename files using the sample identification variable
mv "${read_dir}/${accession}_1.fastq.gz" "${read_dir}/${sample_id}_R1.fastq.gz"
mv "${read_dir}/${accession}_2.fastq.gz" "${read_dir}/${sample_id}_R2.fastq.gz"

echo "Finished renaming the FASTQ files"
