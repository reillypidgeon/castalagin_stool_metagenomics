#!/usr/bin/env bash

#SBATCH --job-name=fastp_bt2
#SBATCH --output=%x_%A_%a.out
#SBATCH --error=%x_%A_%a.err
#SBATCH --time=8:00:00
#SBATCH --array=0-65
#SBATCH --cpus-per-task=8
#SBATCH --mem=100G

set -euo pipefail

# Define variables
#===========================================================================
project_dir="$SCRATCH/PRJEB76307_MGX"

#===========================================================================

# Load modules
module load fastqc/0.12.1 fastp/1.0.1 gcc/14.3
echo "Modules loaded"

# These are the directory variables for samples (containing raw reads) and the newly created output
SAMPLE_DIR=$SCRATCH/RP01-93_CC_CT/RP01-93_CC_CT_raw/ # This directory contains 66 sample directories containing paired-end reads R1 and R2 (downloaded from the ENA)
OUT_DIR=$SCRATCH/RP01-93_CC_CT/RP01-93_CC_CT_fastp_bt2_out
# Create output directory if it doesn't already exist
mkdir -p $OUT_DIR

# Set the location of the bowtie2 index
bt2_db=$SCRATCH/t2t_hg39/

# Build array of directories - all directories have the same sample ID (e.g. 021_V1) as each read set
DIRS=(${SAMPLE_DIR}/*/)
READ_DIR=${DIRS[$SLURM_ARRAY_TASK_ID]}
sample_id=$(basename "$READ_DIR")

R1=$(ls ${READ_DIR}/*_R1*.fastq.gz)
R2=$(ls ${READ_DIR}/*_R2*.fastq.gz)

echo "Sample: $sample_id"
echo "R1: $R1"
echo "R2: $R2"

# Create output directories for each step of filtering, QC, and human genome mapping
FASTQC_OUT=$OUT_DIR/fastqc_out
fastp_out=$OUT_DIR/fastp_out/${sample_id}
BT2_OUT=$OUT_DIR/bt2_out/${sample_id}
mkdir -p $FASTQC_OUT
mkdir -p $fastp_out
mkdir -p $BT2_OUT

# Start with fastqc on the raw reads to see what the quality was like at the start
echo "Running FastQC"
fastqc $R1 $R2 --outdir $FASTQC_OUT \
--threads $SLURM_CPUS_PER_TASK --noextract

# Run fastp to trim adapters and polyG (common with the sequences we get back from the NovaSeq)
# This should detect Illumina TruSeq Adapter sequences as well
echo "Running fastp to trim adapters and overrepresented sequences"
fastp -i $R1 -I $R2 --verbose \
-o $fastp_out/${sample_id}_trim_R1.fastq.gz -O $fastp_out/${sample_id}_trim_R2.fastq.gz \
--detect_adapter_for_pe --trim_poly_g \
--cut_front --cut_tail --cut_window_size 4 \
--cut_mean_quality 20 --length_required 100 \
--thread $SLURM_CPUS_PER_TASK \
--html $fastp_out/${sample_id}_fastp.html \
--json $fastp_out/${sample_id}_fastp.json

echo "Now running FastQC on trimmed reads"
fastqc $fastp_out/${sample_id}_trim_R1.fastq.gz $fastp_out/${sample_id}_trim_R2.fastq.gz \
--outdir $FASTQC_OUT \
--threads $SLURM_CPUS_PER_TASK --noextract

# The above quality filtering and trimming should take about 1h15min for a paired-end sample (2 x 150) where each fastq.gz file is ~8.5 GB
date
echo "Finished with read trimming and quality control"
echo "Now moving on to the removal of host reads using bowtie2"

# Load the required modules
module load bowtie2/2.5.4
echo "Modules loaded"

# Map trimmed reads to the T2T human genome and output aligned and unaligned reads (as fastq.gz)
bowtie2 -x $bt2_db/t2t -p $SLURM_CPUS_PER_TASK \
-1 $fastp_out/${sample_id}_trim_R1.fastq.gz \
-2 $fastp_out/${sample_id}_trim_R2.fastq.gz \
--un-conc-gz $BT2_OUT/${sample_id}_bt2_t2t_unaligned_R%.fastq.gz \
--al-conc-gz $BT2_OUT/${sample_id}_bt2_t2t_aligned_R%.fastq.gz \
--fr --quiet

echo "Mapped MGX reads to T2T human reference genome"
echo "The unaligned reads are needed for downstream analyses like metaphlan and megahit"

echo "Now running FastQC on trimmed unaligned reads"
fastqc $BT2_OUT/${sample_id}_bt2_t2t_unaligned_R1.fastq.gz $BT2_OUT/${sample_id}_bt2_t2t_unaligned_R2.fastq.gz \
--outdir $FASTQC_OUT \
--threads $SLURM_CPUS_PER_TASK --noextract

date
echo "The read cleanup is done for $sample_id"
