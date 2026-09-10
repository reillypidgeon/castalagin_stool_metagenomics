#!/usr/bin/env bash
# Log in to the Digital Research Alliance of Canada Narval Cluster
# From the login node (internet access needed)

set -euo pipefail

# Define variables
#===========================================================================
project_dir="$SCRATCH/PRJEB76307_MGX"
mkdir -p "${project_dir}"

scripts_dir="$SCRATCH/castalagin_stool_metagenomics/PRJEB76307_metagenomics"

# Create a directory for all raw reads data in the scratch directory
read_dir="${project_dir}/raw_reads"
mkdir -p "${read_dir}"
cd "${read_dir}"
#===========================================================================

# Download the raw sequencing data from PRJEB76307 from a list of urls
# Example url: ftp://ftp.sra.ebi.ac.uk/vol1/run/ERR132/ERR13245373/NS.LH00147_0019.004.IDT_i7_213---IDT_i5_213.061_V2_R1.fastq.gz
cat "${scripts_dir}/ena_PRJEB76307_urls.txt" | parallel -j 8 wget -c -nc

echo "Finished downloading reads"

# Submit a scheduled job for FASTQ conversion
echo "Submitting scheduled job to set up FASTQ files for array jobs"
sbatch "${scripts_dir}/ena_PRJEB76307_setup.slurm"
