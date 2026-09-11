#!/usr/bin/env bash

#SBATCH --job-name=RPKM_TPM_merge
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
#SBATCH --time=00:10:00
#SBATCH --mem=16G

set -euo pipefail

# Define variables
#===========================================================================
project_dir="$SCRATCH/PRJEB76307_MGX"
scripts_dir="$SCRATCH/castalagin_stool_metagenomics/PRJEB76307_metagenomics" # Scripts from repository
fc_ra_dir="${project_dir}/fc_ra_out"
#===========================================================================

export fc_ra_dir

# Load modules
module load StdEnv/2023 python/3.13.2 scipy-stack/2026a

# Merge the RPKM and TPM output tables for all samples
# Output in the $fc_ra_dir
python3 "${scripts_dir}/RPKM_TPM_merge.py"
