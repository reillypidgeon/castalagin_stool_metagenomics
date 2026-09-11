#!/usr/bin/env bash

#SBATCH --job-name=diamond_co_merge
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
#SBATCH --time=00:20:00
#SBATCH --mem=16G

set -euo pipefail

# Define variables
#===========================================================================
project_dir="$SCRATCH/PRJEB76307_MGX"
scripts_dir="$SCRATCH/castalagin_stool_metagenomics/PRJEB76307_metagenomics" # Scripts from repository
diamond_dir="${project_dir}/diamond_co_out"
#===========================================================================

cd "${diamond_dir}"

# Load modules
module load StdEnv/2023 python/3.13.2 scipy-stack/2026a

# Merge diamond tables from all samples and create a best-hits FASTA file to search against the UHGP
python3 "${scripts_dir}/diamond_co_best_hits.py"
