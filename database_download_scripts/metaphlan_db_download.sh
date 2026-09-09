#!/usr/bin/env bash
# Log in to the Digital Research Alliance of Canada Narval Cluster

# From the login node (internet access needed)
# The MetaPhlAn database needs to be downloaded to the scratch directory
# Create a directory in $SCRATCH if it doesn't already exist
metaphlan_dir="$SCRATCH/metaphlan_databases"
mkdir -p "${metaphlan_dir}"
cd "${metaphlan_dir}"

# Set the desired database version here
metaphlan_version="mpa_vJun23_CHOCOPhlAnSGB_202403"

# Define the base_url and build links for the desired MetaPhlAn database version (common filename to 7 different files)
base_url="http://cmprod1.cibio.unitn.it/biobakery4/metaphlan_databases/"
bt2_url="${base_url}bowtie2_indexes/"
link="${base_url}${metaphlan_version}"
bt2_link="${bt2_url}${metaphlan_version}"

# Download the required files using parallel wget
parallel -j 7 wget ::: "${link}.md5" "${link}.nwk" "${link}.tar" "${link}_marker_info.txt.bz2" "${link}_species.txt.bz2" "${bt2_link}_bt2.md5" "${bt2_link}_bt2.tar"

# After these are downloaded, request an interactive job (salloc) and untar & unzip the databases
tar -xvf mpa_vJun23_CHOCOPhlAnSGB_202403.tar
parallel bunzip2 ::: *.bz2

echo "Done setting up the MetaPhlAn database"
