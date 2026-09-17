#!/usr/bin/env bash

#SBATCH --job-name=metaphlan
#SBATCH --output=%x_%A_%a.out
#SBATCH --error=%x_%A_%a.err
#SBATCH --time=2:00:00
#SBATCH --array=0-65
#SBATCH --cpus-per-task=8
#SBATCH --mem=100G

set -euo pipefail

# Define common variables
#===========================================================================
project_dir="$SCRATCH/PRJEB76307_MGX"
sample_dir="${project_dir}/fastp_bt2_qc/bt2_out" # This directory contains 66 sample directories containing paired-end reads R1 and R2 (after removing reads mapped to the human genome)
metaphlan_db=$SCRATCH/metaphlan_databases # Version mpa_vJun23_CHOCOPhlAnSGB_202403
metaphlan_index="mpa_vJun23_CHOCOPhlAnSGB_202403"

# Create output directory
out_dir="${project_dir}/metaphlan_out"
mkdir -p "${out_dir}"
#===========================================================================

# Build array of directories to extract sample_id and read paths
#===========================================================================
dirs=(${sample_dir}/*/)
read_dir=${dirs[${SLURM_ARRAY_TASK_ID}]}
sample_id=$(basename "$read_dir")

# The read_dir variable already has a forward slash
R1=$(ls ${read_dir}*unaligned_R1*.fastq.gz)
R2=$(ls ${read_dir}*unaligned_R2*.fastq.gz)

echo "Sample: $sample_id"
echo "R1: $R1"
echo "R2: $R2"
#===========================================================================

# Load modules
module load gcc blast samtools bedtools python/3.13.2 bowtie2/2.5.4 StdEnv/2023

# Generate virtual environment in $SLURM_TMPDIR
virtualenv --no-download ${SLURM_TMPDIR}/env
source ${SLURM_TMPDIR}/env/bin/activate

# Install metaphlan version 4.1.1 and its dependencies from the available wheels
pip install --no-index --upgrade pip
pip install --no-index metaphlan==4.1.1

# Run metaphlan
metaphlan $R1,$R2 \
--input_type fastq \
-o "${out_dir}/${sample_id}_metaphlan_out.txt" \
--nproc ${SLURM_CPUS_PER_TASK} \
--index "${metaphlan_index}" \
--bowtie2db "${metaphlan_db}" \
--bowtie2out "${out_dir}/${sample_id}_metaphlan_out.bowtie2.bz2"

echo "Metaphlan pipeline finished"

# Convert SGB profiles to GTDB taxonomy (using metaphlan utility script)
sgb_to_gtdb_profile.py -d "$metaphlan_db/${metaphlan_index}.pkl" \
-i "${out_dir}/${sample_id}_metaphlan_out.txt" \
-o "${out_dir}/${sample_id}_metaphlan_out_GTDB.tsv"

echo "Converted SGB to GTDB taxonomy for ${sample_id}"
