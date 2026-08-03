#!/usr/bin/env bash

#SBATCH --job-name=fastp_bt2
#SBATCH --output=%x.out
#SBATCH --error=%x.err
#SBATCH --time=14:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=100G

set -euo pipefail
date

# This script works for a single sample
# Note that portability is not the main objective here, but future changes will aim to improve this

# Define variables
#===========================================================================
# These could become positional arguments or optional arguments later on...
READ_DIR="raw_reads"
R1="$READ_DIR/NS.X0107.008.IDT_i7_97---IDT_i5_97.MO67_A-D_R1.fastq.gz"
R2="$READ_DIR/NS.X0107.008.IDT_i7_97---IDT_i5_97.MO67_A-D_R2.fastq.gz"
SAMPLE_ID="MO67"
BT2_DB="$SCRATCH/T2T_hg39/"
#===========================================================================

# Create output directories
OUT_DIR="fastp_bt2_qc"
FASTQC_DIR="$OUT_DIR/fastqc_out"
FASTP_DIR="$OUT_DIR/fastp_out"
BT2_DIR="$OUT_DIR/bt2_out"
mkdir -p "$OUT_DIR" "$FASTQC_DIR" "$FASTP_DIR" "$BT2_DIR"

# Load modules
module load fastqc/0.12.1 fastp/1.0.1

echo "Running FastQC"
fastqc $R1 $R2 --outdir $FASTQC_DIR \
--threads $SLURM_CPUS_PER_TASK --noextract

echo "Running fastp to trim adapters and overrepresented sequences"
fastp -i $R1 -I $R2 --verbose \
-o "$FASTP_DIR/${SAMPLE_ID}_trim_R1.fastq.gz" \
-O "$FASTP_DIR/${SAMPLE_ID}_trim_R2.fastq.gz" \
--detect_adapter_for_pe --trim_poly_g \
--cut_front --cut_tail --cut_window_size 4 \
--cut_mean_quality 20 --length_required 100 \
--thread $SLURM_CPUS_PER_TASK \
--html "${SAMPLE_ID}_fastp.html" --json "${SAMPLE_ID}_fastp.json"

echo "Now running FastQC on trimmed reads"
fastqc "$FASTP_DIR/${SAMPLE_ID}_trim_R1.fastq.gz" "$FASTP_DIR/${SAMPLE_ID}_trim_R2.fastq.gz" \
--outdir $FASTQC_DIR \
--threads $SLURM_CPUS_PER_TASK --noextract

date
echo "Now moving on to the removal of host reads using bowtie2"

# Load the required modules
module load bowtie2/2.5.4
echo "Modules loaded"

# Map trimmed reads to the human genome (GCF_009914755.1_T2T-CHM13v2.0_genomic.fna)
# Output both aligned and unaligned reads (as fastq.gz)
bowtie2 -x "$BT2_DB/t2t" -p $SLURM_CPUS_PER_TASK \
-1 "$FASTP_DIR/${SAMPLE_ID}_trim_R1.fastq.gz" \
-2 "$FASTP_DIR/${SAMPLE_ID}_trim_R2.fastq.gz" \
--un-conc-gz "$BT2_DIR/${SAMPLE_ID}_bt2_t2t_unaligned_R%.fastq.gz" \
--al-conc-gz "$BT2_DIR/${SAMPLE_ID}_bt2_t2t_aligned_R%.fastq.gz" \
--fr --quiet

echo "The unaligned reads will be used in downstream analyses like metaphlan and megahit"

echo "Now running FastQC on trimmed unaligned reads"
fastqc "$BT2_DIR/${SAMPLE_ID}_bt2_t2t_unaligned_R1.fastq.gz" "$BT2_DIR/${SAMPLE_ID}_bt2_t2t_unaligned_R2.fastq.gz" \
--outdir $FASTQC_DIR \
--threads $SLURM_CPUS_PER_TASK --noextract

date
echo "The read cleanup is done"
