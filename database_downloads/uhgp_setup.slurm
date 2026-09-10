#!/usr/bin/env bash

#SBATCH --job-name=uhgp_setup
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
#SBATCH --time=02:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G

set -euo pipefail

# Unzip the tar.gz files and delete the gz files afterwards
tar -xvf uhgp-100.tar.gz
rm *.gz

# Rename the metadata file
mv genomes-all_metadata.tsv uhgp_genomes_all_metadata.tsv

# Build diamond databases using the uhgp-100 FASTA file
module load diamond/2.1.22

diamond makedb --in uhgp-100/uhgp-100.faa -d uhgp-100

echo "Finished UHGP database setup"
