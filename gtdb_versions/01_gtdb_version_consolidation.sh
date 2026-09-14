#!/usr/bin/env bash
# Log in to the Digital Research Alliance of Canada Narval Cluster

# From the login node (internet access needed)
scripts_dir="$SCRATCH/castalagin_stool_metagenomics/gtdb_versions"

# Create a directory in $SCRATCH if it doesn't already exist
out_dir="$SCRATCH/gtdb_versions"
mkdir -p "${out_dir}"
cd "${out_dir}"

# Define the base_url and build links for the desired MetaPhlAn database version (common filename to 7 different files)
base_url="https://data.gtdb.ecogenomic.org/releases"
gtdb_r202="${base_url}/release202/202.0/bac120_metadata_r202.tar.gz"
gtdb_r207="${base_url}/release207/207.0/bac120_metadata_r207.tar.gz"
gtdb_r232="${base_url}/release232/232.0/bac120_metadata_r232.tsv.gz"

# Download the required files using parallel wget
parallel -j 3 wget ::: "${gtdb_r202}" "${gtdb_r207}" "${gtdb_r232}"

# Download and install tidyverse if not already done
module load StdEnv/2023 gcc/12.3 r/4.6.1

Rscript << 'EOF'
if (!requireNamespace("dplyr", quietly = TRUE)) {install.packages("dplyr")}
EOF

# After these are downloaded, schedule a job to untar & unzip the database
echo "Scheduling a job to set extract files and merge GTDB metadata"
sbatch "${scripts_dir}/gtdb_version_consolidation.slurm" # Note that the R script can also be executed interactively using salloc --mem=16G
