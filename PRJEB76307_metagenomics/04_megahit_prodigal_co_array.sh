#!/usr/bin/env bash

#SBATCH --job-name=megahit_prodigal_co
#SBATCH --output=%x_%A_%a.out
#SBATCH --error=%x_%A_%a.err
#SBATCH --time=24:00:00
#SBATCH --array=1-33
#SBATCH --cpus-per-task=10
#SBATCH --mem=100G

set -euo pipefail

# These are the directory variables for samples
SAMPLE_DIR=$SCRATCH/RP01-93_CC_CT/RP01-93_CC_CT_fastp_bt2_out/bt2_out
OUT_DIR=$SCRATCH/RP01-93_CC_CT/RP01-93_CC_CT_analysis
mkdir -p $OUT_DIR

# Create output directory for megahit
MEGAHIT_OUT=$OUT_DIR/megahit_co_assembly_out
mkdir -p $MEGAHIT_OUT

# Build patient list once per job array run (on the first instance)
if [[ $SLURM_ARRAY_TASK_ID -eq 1 ]]; then
    echo "Building patient list..."
    # sed 's/_.*//' (below) is used to remove everything from the first underscore (_) to the end of each line in a text stream
    ls "$SAMPLE_DIR" | sed 's/_.*//' | sort -u > patient_ids.txt
fi

# Short delay so other tasks don't try to read before the patient_id file exists
sleep 5

# Get patient ID for this SLURM task
# Note that starting at index 0 returns an error with this sed command
P_ID=$(sed -n "${SLURM_ARRAY_TASK_ID}p" patient_ids.txt)
echo "SLURM task ${SLURM_ARRAY_TASK_ID} | Patient: $P_ID"
echo

# Now get timepoint directories
TIME_DIRS=$(ls -d ${SAMPLE_DIR}/${P_ID}_* 2>/dev/null)

if [[ -z "$TIME_DIRS" ]]; then
    echo "ERROR: No directories found for patient $P_ID"
    exit 1
fi

echo "Timepoint directories: $TIME_DIRS"

# Get the reads from each patient at both timepoints - these will be used in the co-assemblies
R1_FILES=$(find $TIME_DIRS -type f -name "*unaligned_R1*.fastq.gz" | tr '\n' ',' | sed 's/,$//')
R2_FILES=$(find $TIME_DIRS -type f -name "*unaligned_R2*.fastq.gz" | tr '\n' ',' | sed 's/,$//')

if [[ -z "$R1_FILES" || -z "$R2_FILES" ]]; then
    echo "ERROR: Missing R1 or R2 files for patient $PID"
    exit 1
fi

echo "R1: $R1_FILES"
echo "R2: $R2_FILES"

# Load the required modules for megahit and prodigal
module load megahit/1.2.9 StdEnv/2023 prodigal/2.6.3
echo "Modules loaded"

# Invoke megahit
# Run megahit on the bt2 unmapped reads
megahit -1 $R1_FILES -2 $R2_FILES \
--presets meta-sensitive \
--continue \
--min-contig-len 500 \
-t $SLURM_CPUS_PER_TASK \
--out-dir $MEGAHIT_OUT/${P_ID}

date
echo "The megahit analysis is done for $P_ID"

# Change the name of the output to include the sample ID
mv $MEGAHIT_OUT/${P_ID}/final.contigs.fa $MEGAHIT_OUT/${P_ID}/${P_ID}_final.contigs.fa

# Now run prodigal on the final contigs for each sample, which should take less than 1 h

# Set variable for the directory containing trimmed, bowtie2_unmapped reads
CONTIG_DIR=$MEGAHIT_OUT/${P_ID}
PRODIGAL_OUT=$OUT_DIR/prodigal_co_assembly_out
mkdir -p $PRODIGAL_OUT
mkdir -p $PRODIGAL_OUT/${P_ID}

# Uses the Standard Bacteria/Archaea translation table (11)
prodigal -i $CONTIG_DIR/${P_ID}_final.contigs.fa \
-p meta \
-g 11 \
-a $PRODIGAL_OUT/${P_ID}/${P_ID}_prodigal_proteins.faa \
-d $PRODIGAL_OUT/${P_ID}/${P_ID}_prodigal_genes.fna \
-o $PRODIGAL_OUT/${P_ID}/${P_ID}_prodigal_annot.gff

echo "Finished running prodigal on $P_ID"
date
