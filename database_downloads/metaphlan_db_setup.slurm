#!/usr/bin/env bash

#SBATCH --job-name=metaphlan_db_setup
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
#SBATCH --time=02:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G

set -euo pipefail

# Untar and unzip
tar -xvf mpa_vJun23_CHOCOPhlAnSGB_202403.tar
parallel bunzip2 ::: *.bz2

echo "Finished MetaPhlAn database setup"
