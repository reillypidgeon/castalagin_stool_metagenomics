#!/usr/bin/env bash

#SBATCH --job-name=fastp_bt2
#SBATCH --output=%x_%A_%a.out
#SBATCH --error=%x_%A_%a.err
#SBATCH --time=3:00:00
#SBATCH --array=0-65
#SBATCH --cpus-per-task=8
#SBATCH --mem=100G

set -euo pipefail

# Define common variables
#===========================================================================
project_dir="$SCRATCH/PRJEB76307_MGX"
sample_dir="${project_dir}/raw_reads" # This directory contains 66 sample directories containing paired-end reads R1 and R2 (downloaded from the ENA)
bt2_db="$SCRATCH/t2t_hg39/"

# Create output directory
out_dir="${project_dir}/fastp_bt2_qc"
mkdir -p "${out_dir}"
#===========================================================================

# Build array of directories to extract sample_id and read paths
#===========================================================================
dirs=(${sample_dir}/*/)
read_dir=${dirs[${SLURM_ARRAY_TASK_ID}]}
sample_id=$(basename "$read_dir")

# The read_dir variable already has a forward slash
R1=$(ls ${read_dir}*_R1*.fastq.gz)
R2=$(ls ${read_dir}*_R2*.fastq.gz)

echo "Sample: ${sample_id}"
echo "R1: $R1"
echo "R2: $R2"

# Create output directories for each tool
fastqc_dir="${out_dir}/fastqc_out"
fastp_dir="${out_dir}/fastp_out/${sample_id}"
bt2_dir="${out_dir}/bt2_out/${sample_id}"
mkdir -p "${fastqc_dir}" "${fastp_dir}" "${bt2_dir}"
#===========================================================================

# Load modules
module load fastqc/0.12.1 fastp/1.0.1

echo "Running FastQC"
fastqc $R1 $R2 \
--outdir "${fastqc_dir}" \
--threads ${SLURM_CPUS_PER_TASK} --noextract

echo "Running fastp to trim adapters and overrepresented sequences"
fastp -i $R1 -I $R2 --verbose \
-o "${fastp_dir}/${sample_id}_trim_R1.fastq.gz" \
-O "${fastp_dir}/${sample_id}_trim_R2.fastq.gz" \
--detect_adapter_for_pe --trim_poly_g \
--cut_front --cut_tail --cut_window_size 4 \
--cut_mean_quality 20 --length_required 100 \
--thread ${SLURM_CPUS_PER_TASK} \
--html "${fastp_dir}/${sample_id}_fastp.html" \
--json "${fastp_dir}/${sample_id}_fastp.json"

echo "Now running FastQC on trimmed reads"
fastqc "${fastp_dir}/${sample_id}_trim_R1.fastq.gz" "${fastp_dir}/${sample_id}_trim_R2.fastq.gz" \
--outdir "${fastqc_dir}" \
--threads ${SLURM_CPUS_PER_TASK} --noextract

echo "Now moving on to the removal of host reads using bowtie2"

# Load modules
module load bowtie2/2.5.4

# Map trimmed reads to the human genome (GCF_009914755.1_T2T-CHM13v2.0_genomic.fna)
# Output both aligned and unaligned reads (as fastq.gz)
bowtie2 -x "${bt2_db}/t2t" -p ${SLURM_CPUS_PER_TASK} \
-1 "${fastp_dir}/${sample_id}_trim_R1.fastq.gz" \
-2 "${fastp_dir}/${sample_id}_trim_R2.fastq.gz" \
--un-conc-gz "${bt2_dir}/${sample_id}_bt2_t2t_unaligned_R%.fastq.gz" \
--al-conc-gz "${bt2_dir}/${sample_id}_bt2_t2t_aligned_R%.fastq.gz" \
--fr --quiet

echo "The unaligned reads will be used in downstream analyses like metaphlan and megahit"

echo "Now running FastQC on trimmed unaligned reads"
fastqc "${bt2_dir}/${sample_id}_bt2_t2t_unaligned_R1.fastq.gz" "${bt2_dir}/${sample_id}_bt2_t2t_unaligned_R2.fastq.gz" \
--outdir "${fastqc_dir}" \
--threads ${SLURM_CPUS_PER_TASK} --noextract

echo "The read cleanup is done for $sample_id"
