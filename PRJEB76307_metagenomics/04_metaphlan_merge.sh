#!/usr/bin/env bash

#SBATCH --job-name=metaphlan_merge
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
#SBATCH --time=00:10:00
#SBATCH --mem=16G

set -euo pipefail

# Define variables
#===========================================================================
project_dir="$SCRATCH/PRJEB76307_MGX"
scripts_dir="$SCRATCH/castalagin_stool_metagenomics/PRJEB76307_metagenomics" # Scripts from repository
#===========================================================================

cd "${project_dir}"

# Load modules
module load StdEnv/2023 python/3.13.2 scipy-stack/2026a

# Merge the MetaPhlAn output tables for all samples
python3 "${scripts_dir}/metaphlan_merge.py"
