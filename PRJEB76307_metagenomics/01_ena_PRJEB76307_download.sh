#!/usr/bin/env bash
# Log in to the Digital Research Alliance of Canada Narval Cluster
# From the login node (internet access needed)

# IMPORTANT: These files can also be downloaded via Globus via the EMBL-EBI Public Data collection
# The links are the same as in the $urls_file
# Do this if you run into any issues with the downloads

set -euo pipefail

# Define variables
#===========================================================================
project_dir="$SCRATCH/PRJEB76307_MGX"
mkdir -p "${project_dir}"

scripts_dir="$SCRATCH/castalagin_stool_metagenomics/PRJEB76307_metagenomics"

urls_file="${scripts_dir}/ena_PRJEB76307_urls.txt"

# Create a directory for all raw reads data in the scratch directory
read_dir="${project_dir}/raw_reads"
mkdir -p "${read_dir}"
#===========================================================================

cd "${read_dir}"

# Remove urls that have already been downloaded and processed
urls_file_to_download="${scripts_dir}/ena_PRJEB76307_urls_to_download.txt"
> "${urls_file_to_download}"

while IFS= read -r line; do
    subject_id=$(echo $line | grep -Eo "0[0-9]{2}_V[1-4]")
    new_file_name=$(echo $line | grep -Eo "0[0-9]{2}_V[1-4]_R[1-2]\.fastq\.gz")
    processed_file="${subject_id}/${new_file_name}"
    
    if [[ -f "${processed_file}" ]]; then
        echo "Genome ${new_file_name} has already been processed. Skipping..."
        continue
    else
        echo "Adding ${new_file_name} to the list of URLs to download"
    fi
    echo "$line" >> "${urls_file_to_download}"
done < "${urls_file}"

echo "Starting download of PRJEB76307 sequencing reads"

if [[ ! -s "${urls_file_to_download}" ]]; then
    echo "Nothing to download."
    exit 0
fi

# Download the raw sequencing data from PRJEB76307 from a list of urls
if ! parallel -j 6 \
    --joblog "${scripts_dir}/wget.log" \
    wget -c :::: "${urls_file_to_download}"
then
    echo "Warning: One or more downloads failed."
    echo "See ${scripts_dir}/wget.log for details."
fi

echo "Finished downloading reads"

# Submit a scheduled job for FASTQ conversion
echo "Submitting scheduled job to set up FASTQ files for array jobs"
sbatch "${scripts_dir}/ena_PRJEB76307_setup.slurm"
