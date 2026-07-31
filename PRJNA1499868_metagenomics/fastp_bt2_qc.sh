#!/bin/bash

#SBATCH --job-name=fastp_bt2
#SBATCH --output=%x.out
#SBATCH --error=%x.err
#SBATCH --time=14:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=100G


date

#===========================================================================
# Define variables and paths for this specific sample
READ_DIR=$HOME/projects/def-castagne/rpidgeon/RP01-94_20240903_MO67_MGX_MTX
R1=$READ_DIR/NS.X0107.008.IDT_i7_97---IDT_i5_97.MO67_A-D_R1.fastq.gz
R2=$READ_DIR/NS.X0107.008.IDT_i7_97---IDT_i5_97.MO67_A-D_R2.fastq.gz
SAMPLE_ID="MO67"
OUT_DIR=$SCRATCH/RP01-94_MO67_MGX/fastp_bt2_qc
mkdir -p $OUT_DIR
#===========================================================================

# Create output directories
FASTQC_DIR=$OUT_DIR/fastqc
mkdir -p $FASTQC_DIR
FASTP_DIR=$OUT_DIR/fastp_out
mkdir -p $FASTP_DIR

# Load modules
module load fastqc/0.12.1 fastp/1.0.1

echo "Running FastQC"
fastqc $R1 $R2 --outdir $FASTQC_DIR \
--threads $SLURM_CPUS_PER_TASK --noextract

echo "Running fastp to trim adapters and overrepresented sequences"
fastp -i $R1 -I $R2 --verbose \
-o ${SAMPLE_ID}_trim_R1.fastq.gz -O ${SAMPLE_ID}_trim_R2.fastq.gz \
--detect_adapter_for_pe --trim_poly_g \
--cut_front --cut_tail --cut_window_size 4 \
--cut_mean_quality 20 --length_required 100 \
--thread $SLURM_CPUS_PER_TASK \
--html ${SAMPLE_ID}_fastp.html --json ${SAMPLE_ID}_fastp.json

echo "Now running FastQC on trimmed reads"
fastqc ${SAMPLE_ID}_trim_R1.fastq.gz ${SAMPLE_ID}_trim_R2.fastq.gz \
--outdir $FASTQC_DIR \
--threads $SLURM_CPUS_PER_TASK --noextract

date
echo "Now moving on to the removal of host reads using bowtie2"

# Load the required modules
module load bowtie2/2.5.4
echo "Modules loaded"

# Create new directory for the bowtie2 output
BT2_OUT=$OUT_DIR/bt2_out
mkdir -p $BT2_OUT

# Set the location of the bowtie2 index (has already been created) using the commented code below
	#cd $SCRATCH/T2T_hg39
	#bowtie2-build GCF_009914755.1_T2T-CHM13v2.0_genomic.fna t2t -q -t $SLURM_CPUS_PER_TASK
	#echo "Built human reference genome from GCF_009914755"

BT2_DB=$SCRATCH/T2T_hg39/

# Map trimmed reads to the T2T human genome (GCF_009914755.1_T2T-CHM13v2.0_genomic.fna) and output both aligned and unaligned reads (as fastq.gz)
bowtie2 -x $BT2_DB/t2t -p $SLURM_CPUS_PER_TASK \
-1 $FASTP_OUT/${SAMPLE_ID}_trim_R1.fastq.gz \
-2 $FASTP_OUT/${SAMPLE_ID}_trim_R2.fastq.gz \
--un-conc-gz $BT2_OUT/${SAMPLE_ID}_bt2_t2t_unaligned_R%.fastq.gz \
--al-conc-gz $BT2_OUT/${SAMPLE_ID}_bt2_t2t_aligned_R%.fastq.gz \
--fr --quiet

echo "Mapped MGX reads to T2T_hg39 human reference genome"
echo "The unaligned reads are needed for downstream analyses like metaphlan and megahit"

echo "Now running FastQC on trimmed hg39_unaligned reads"
fastqc $BT2_OUT/${SAMPLE_ID}_bt2_t2t_unaligned_R1.fastq.gz $BT2_OUT/${SAMPLE_ID}_bt2_t2t_unaligned_R2.fastq.gz \
--outdir $FASTQC_OUT \
--threads $SLURM_CPUS_PER_TASK --noextract

date
echo "The read cleanup is done"
