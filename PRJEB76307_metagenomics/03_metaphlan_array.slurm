#!/usr/bin/env bash

#SBATCH --job-name=metaphlan
#SBATCH --output=%x_%A_%a.out
#SBATCH --error=%x_%A_%a.err
#SBATCH --time=6:00:00
#SBATCH --array=0-65
#SBATCH --cpus-per-task=8
#SBATCH --mem=100G

date

# Load the required modules
module load gcc blast samtools bedtools python/3.13.2 bowtie2/2.5.4 StdEnv/2023
echo "Modules loaded"

# These are the directory variables for samples
SAMPLE_DIR=$SCRATCH/RP01-93_CC_CT/RP01-93_CC_CT_fastp_bt2_out/bt2_out # This directory contains 66 sample directories containing paired-end reads R1 and R2
OUT_DIR=$SCRATCH/RP01-93_CC_CT/RP01-93_CC_CT_analysis
mkdir -p $OUT_DIR

# Create output directory
METAPHLAN_OUT=$OUT_DIR/metaphlan_out
mkdir -p $METAPHLAN_OUT

# Build array of directories - all directories have the same sample ID (e.g. 021_V1) as each read set
DIRS=(${SAMPLE_DIR}/*/)
READ_DIR=${DIRS[$SLURM_ARRAY_TASK_ID]}
SAMPLE_ID=$(basename "$READ_DIR")

# Only analyze the unaligned samples since these contain reads that did not match to the human genome
# Note that the $READ_DIR variable contains a / at the end already
R1=$(ls ${READ_DIR}*unaligned_R1*.fastq.gz)
R2=$(ls ${READ_DIR}*unaligned_R2*.fastq.gz)

echo "Sample: $SAMPLE_ID"
echo "R1: $R1"
echo "R2: $R2"

# Set variable for the directory containing the metaphlan database mpa_vJun23_CHOCOPhlAnSGB_202403

DB_DIR=$SCRATCH/metaphlan_databases

# Generate virtual environment in $SLURM_TMPDIR
virtualenv --no-download ${SLURM_TMPDIR}/env
source ${SLURM_TMPDIR}/env/bin/activate

# Install metaphlan_4.1.1 and its dependencies
pip install --no-index --upgrade pip
pip install --no-index metaphlan==4.1.1  # EDIT: the required version here, e.g. 4.1.1
echo "Metaphlan installation successful"

# Run metaphlan
metaphlan $R1,$R2 \
--input_type fastq \
-o $METAPHLAN_OUT/${SAMPLE_ID}_metaphlan_out.txt \
--nproc $SLURM_CPUS_PER_TASK \
--index mpa_vJun23_CHOCOPhlAnSGB_202403 \
--bowtie2db $DB_DIR \
--bowtie2out $METAPHLAN_OUT/${SAMPLE_ID}_metaphlan_out.bowtie2.bz2

echo "Metaphlan pipeline finished"

# Convert SGB profiles to GTDB taxonomy
sgb_to_gtdb_profile.py -d $DB_DIR/mpa_vJun23_CHOCOPhlAnSGB_202403.pkl \
-i $METAPHLAN_OUT/${SAMPLE_ID}_metaphlan_out.txt \
-o $METAPHLAN_OUT/${SAMPLE_ID}_metaphlan_out_GTDB.tsv

echo "Converted SGB to GTDB taxonomy"

date
echo "The metaphlan analysis is done for $SAMPLE_ID"
