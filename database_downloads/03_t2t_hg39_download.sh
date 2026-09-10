#!/usr/bin/env bash
# Log in to the Digital Research Alliance of Canada Narval Cluster

# From the login node (internet access needed)
scripts_dir="$SCRATCH/castalagin_stool_metagenomics/database_downloads"

# Create a directory for the telomere-to-telomere (T2T-CHM13v2.0) human genome in the scratch directory
t2t_dir="$SCRATCH/t2t_hg39"
mkdir -p "${t2t_dir}"
cd "${t2t_dir}"

# Download the data from the NCBI FTP site
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/009/914/755/GCF_009914755.1_T2T-CHM13v2.0/GCF_009914755.1_T2T-CHM13v2.0_genomic.fna.gz

# Submit a scheduled job to unzip the .fna.gz file and create a bowtie2 database
echo "Scheduling a job to set up the t2t database"
sbatch "${scripts_dir}/t2t_hg39_setup.slurm"
