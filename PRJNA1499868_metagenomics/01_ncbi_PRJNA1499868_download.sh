#!/usr/bin/env bash
# Log in to the Digital Research Alliance of Canada Narval Cluster
# From the login node (internet access needed)

set -euo pipefail

# Define variables
#===========================================================================
project_dir="$SCRATCH/PRJNA1499868_MGX"
mkdir -p "${project_dir}"

scripts_dir="$SCRATCH/castalagin_stool_metagenomics/PRJNA1499868_metagenomics"
sample_id="MO67"
accession="SRR39796052"

# Create a directory for all raw reads data in the scratch directory
read_dir="${project_dir}/raw_reads"
mkdir -p "${read_dir}"
#===========================================================================

# Download the raw sequencing data from PRJNA1499868 using the NCBI sra-toolkit
module load sra-toolkit

prefetch "$accession" \
    --output-directory "${read_dir}" \
    --max-size 100G

vdb-validate "${read_dir}/$accession"

# Submit a scheduled job for FASTQ conversion
echo "Submitting scheduled job to set up FASTQ files"
sbatch "${scripts_dir}/ncbi_PRJNA1499868_setup.slurm" "$accession" "${read_dir}" "${sample_id}
