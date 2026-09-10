#!/usr/bin/env bash

#SBATCH --job-name=PRJNA1499868_setup
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
#SBATCH --time=00:15:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G

set -euo pipefail

module load sra-toolkit


# Define variables
accession="$1"
read_dir="$2"
sra_dir="${read_dir}/$accession"

tmp="${SLURM_TMPDIR}/sra_tmp"
mkdir -p "$tmp"

echo "Starting FASTQ extraction for ${accession}"

fasterq-dump \
    "${sra_dir}" \
    --split-files \
    --threads "${SLURM_CPUS_PER_TASK}" \
    --temp "$tmp" \
    --outdir "${read_dir}"

rm -r ${sra_dir}

echo "Compressing FASTQ files..."

gzip -v "${read_dir}/${accession}_1.fastq"
gzip -v "${read_dir}/${accession}_2.fastq"

echo "Finished zipping FASTQ files"

# Rename files using the sample identification
sample_id="MO67"
