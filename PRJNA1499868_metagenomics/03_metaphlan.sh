#!/usr/bin/env bash

#SBATCH --job-name=metaphlan
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
#SBATCH --time=6:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=100G

set -euo pipefail

# Define variables
#=======================================================================
project_dir="$SCRATCH/PRJNA1499868_MGX"
read_dir="${project_dir}/fastp_bt2_qc/bt2_out/"
sample_id="MO67"
R1="${read_dir}/${sample_id}_bt2_t2t_unaligned_R1.fastq.gz"
R2="${read_dir}/${sample_id}_bt2_t2t_unaligned_R2.fastq.gz"
metaphlan_db="$SCRATCH/metaphlan_databases"

# Create output directory
out_dir="${project_dir}/metaphlan_out"
mkdir -p "${out_dir}"
#=======================================================================

# Load the required modules
module load gcc blast samtools bedtools python/3.13.2 bowtie2 StdEnv/2023

# Generate your virtual environment in $SLURM_TMPDIR
virtualenv --no-download ${SLURM_TMPDIR}/env
source ${SLURM_TMPDIR}/env/bin/activate

# Install metaphlan_4.1.1 and its dependencies (from available Python wheels)
pip install --no-index --upgrade pip
pip install --no-index metaphlan==4.1.1

# Run metaphlan
metaphlan $R1,$R2 \
--input_type fastq \
-o "${out_dir}/${sample_id}_metaphlan_out.txt" \
--nproc $SLURM_CPUS_PER_TASK \
--index mpa_vJun23_CHOCOPhlAnSGB_202403 \
--bowtie2db "${metaphlan_db}" \
--bowtie2out "${out_dir}/${sample_id}_metaphlan_out.bowtie2.bz2"

echo "Metaphlan pipeline finished"

# Convert SGB profiles to GTDB taxonomy (using metaphlan utility script)
sgb_to_gtdb_profile.py -d "${metaphlan_db}/mpa_vJun23_CHOCOPhlAnSGB_202403.pkl" \
-i "${out_dir}/${sample_id}_metaphlan_out.txt" \
-o "${out_dir}/${sample_id}_metaphlan_out_GTDB.txt"

echo "Converted SGB to GTDB taxonomy"
