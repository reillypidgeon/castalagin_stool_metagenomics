#!/usr/bin/env bash

set -euo pipefail

# Define directories
project_dir="$SCRATCH/PRJNA1499868_MGX"
mkdir -p "${project_dir}"
scripts_dir="$SCRATCH/castalagin_stool_metagenomics/PRJNA1499868_metagenomics"

# Create a directory for all raw reads data in the scratch directory
read_dir="${project_dir}/raw_reads"
mkdir -p "${read_dir}"

# Download the raw sequencing data from PRJNA1499868 using the NCBI sra-toolkit
module load sra-toolkit

accession="SRR39796052"

prefetch "$accession" \
    --output-directory "${read_dir}" \
    --max-size 100G

vdb-validate "${read_dir}/$accession"

# Submit a scheduled job for FASTQ conversion
echo "Submitting scheduled job to set up FASTQ files"
sbatch "${scripts_dir}/ncbi_PRJNA1499868_setup.slurm" "$accession" "${read_dir}"
