#!/usr/bin/env bash
# Log in to the Digital Research Alliance of Canada Narval Cluster

# From the login node (internet access needed)
scripts_dir="$SCRATCH/castalagin_stool_metagenomics/database_downloads"

# Create a directory for all UHGP data in the scratch directory
uhgp_dir="$SCRATCH/uhgp"
mkdir -p "${uhgp_dir}"
cd "${uhgp_dir}"

# Download the required UHGP data and metadata (protein clustering at 100 percent identity)
parallel wget ::: https://ftp.ebi.ac.uk/pub/databases/metagenomics/mgnify_genomes/human-gut/v2.0.2/protein_catalogue/uhgp-100.tar.gz \
https://ftp.ebi.ac.uk/pub/databases/metagenomics/mgnify_genomes/human-gut/v2.0.2/genomes-all_metadata.tsv

# Submit a scheduled job to unzip the .tar.gz and create a diamond database
sbatch --wait "${scripts_dir}/uhgp_setup.slurm"

echo "The UHGP database is now set up for further querying using sequences of interest"
