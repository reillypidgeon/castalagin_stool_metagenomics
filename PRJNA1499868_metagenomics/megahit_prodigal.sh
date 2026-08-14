#!/usr/bin/env bash

#SBATCH --job-name=MO67_megahit_prodigal
#SBATCH --output=%x.out
#SBATCH --error=%x.err
#SBATCH --time=20:00:00
#SBATCH --cpus-per-task=12
#SBATCH --mem=120G

set -euo pipefail
date

# Load the required modules
module load megahit/1.2.9 StdEnv/2023
echo "Modules loaded"

# Set variables
# DO NOT create a new directory for megahit - it will create one in the --out-dir portion and cannot already exist
#============================================================================
READ_DIR="fastp_bt2_qc/bt2_out/"
SAMPLE_ID="MO67"
R1=$READ_DIR/${SAMPLE_ID}_bt2_t2t_unaligned_R1.fastq.gz
R2=$READ_DIR/${SAMPLE_ID}_bt2_t2t_unaligned_R2.fastq.gz
#============================================================================

# Run megahit on the MO67 bt2 unmapped reads
megahit -1 $R1 -2 $R2 \
--presets meta-sensitive \
--continue \
--min-contig-len 500 \
-t $SLURM_CPUS_PER_TASK \
--out-dir megahit_out

# Rename megahit output
mv "megahit_out/final.contigs.fa" "megahit_out/{SAMPLE_ID}_final.contigs.fa"

echo "Finished running megahit"
date

echo "Starting prodigal workflow from megahit assembly"

# Load required modules for megahit
module load prodigal/2.6.3
echo "Modules loaded"

# Set variable for the directory containing bowtie2_unmapped reads
MEGAHIT_DIR="megahit_out"
PRODIGAL_DIR="prodigal_out"
mkdir -p $PRODIGAL_DIR

# Run prodigal on the contigs
# Uses the Standard Bacteria/Archaea translation table (11)
prodigal -i "$MEGAHIT_DIR/{SAMPLE_ID}_final.contigs.fa" \
-p meta \
-g 11 \
-a "$PRODIGAL_DIR/{SAMPLE_ID}_prodigal_proteins.faa" \
-d "$PRODIGAL_DIR/{SAMPLE_ID}_prodigal_genes.fna" \
-o "$PRODIGAL_DIR/{SAMPLE_ID}_prodigal_annot.gff"

echo "Finished running prodigal"
date
