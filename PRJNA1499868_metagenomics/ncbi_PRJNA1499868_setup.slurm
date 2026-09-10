#!/usr/bin/env bash

#SBATCH --job-name=PRJNA1499868_setup
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
#SBATCH --time=12:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G

set -euo pipefail

module load sra-toolkit


# Define variables
accession="$1"
reads_dir="$2"
sra_dir="${reads_dir}/$accession"

tmp="${SLURM_TMPDIR}/sra_tmp"
mkdir -p "$tmp"

echo "Starting FASTQ extraction for ${accession}"

fasterq-dump \
    "${sra_dir}" \
    --split-files \
    --threads "$SLURM_CPUS_PER_TASK" \
    --temp "$tmp" \
    --outdir "${reads_dir}"

rm -r ${sra_dir}

echo "Compressing FASTQ files..."

gzip -v "${reads_dir}/${accession}_1.fastq"
gzip -v "${reads_dir}/${accession}_2.fastq"

echo "Finished zipping FASTQ files"
