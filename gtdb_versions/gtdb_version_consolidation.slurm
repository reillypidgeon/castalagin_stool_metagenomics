#!/usr/bin/env bash

#SBATCH --job-name=gtdb_version_setup
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
#SBATCH --time=00:30:00
#SBATCH --cpus-per-task=2
#SBATCH --mem=16G

set -euo pipefail

echo "Starting setup"

scripts_dir="$SCRATCH/castalagin_stool_metagenomics/gtdb_versions"

# Untar and unzip
tar -xvzf bac120_metadata_r202.tar.gz
tar -xvzf bac120_metadata_r207.tar.gz
gunzip bac120_metadata_r232.tsv.gz
rm *.tar.gz

# Load modules
module load r/4.6.1

# Merge the metadata tables using the R script
Rscript "${scripts_dir}/gtdb_version_consolidation.R"

echo "Finished merging GTDB version tables"
