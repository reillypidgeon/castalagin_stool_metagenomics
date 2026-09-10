#!/usr/bin/env bash

#SBATCH --job-name=t2t_hg39_setup
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
#SBATCH --time=02:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G

set -euo pipefail

# Define variables
#===========================================================================
fasta="GCF_009914755.1_T2T-CHM13v2.0_genomic.fna"
db_name="t2t"
#===========================================================================

# Unzip the .fna.gz file and delete it afterwards
gunzip "${fasta}.gz"

# Build bowtie2 database using the unzipped FASTA file
module load bowtie2/2.5.4

bowtie2-build "$fasta" "${db_name}" -q -t ${SLURM_CPUS_PER_TASK}

echo "Finished building human reference genome from $fasta"
