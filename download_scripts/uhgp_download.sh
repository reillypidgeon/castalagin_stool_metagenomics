#!/usr/bin/env bash
# Log in to the Digital Research Alliance of Canada Cluster (Narval)

# From the login node (internet access needed)
# Move to the scratch directory and create a directory for all UHGP data
cd $SCRATCH
mkdir -p uhgp
cd uhgp

# Download the required UHGP data and metadata (protein clusters at 100 and 95 percent identity)
parallel wget ::: https://ftp.ebi.ac.uk/pub/databases/metagenomics/mgnify_genomes/human-gut/v2.0.2/protein_catalogue/uhgp-100.tar.gz https://ftp.ebi.ac.uk/pub/databases/metagenomics/mgnify_genomes/human-gut/v2.0.2/genomes-all_metadata.tsv

# Start an interactive job before proceeding with the following steps (uncomment the line below)
# salloc --mem=16G --time=2:00:00

# Unzip the tar.gz files and delete the gz files afterwards
tar -xvf uhgp-100.tar.gz
rm *.gz

# Rename the metadata file
mv genomes-all_metadata.tsv uhgp_genomes_all_metadata.tsv

# Build diamond databases using both uhgp clusters
module load diamond/2.1.22

diamond makedb --in uhgp-100/uhgp-100.faa -d uhgp-100

# The UHGP database is now set up for further querying using sequences of interest
