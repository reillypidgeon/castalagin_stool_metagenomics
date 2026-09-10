#!/usr/bin/env bash

#SBATCH --job-name=megahit_prodigal_co
#SBATCH --output=%x_%A_%a.out
#SBATCH --error=%x_%A_%a.err
#SBATCH --time=24:00:00
#SBATCH --array=1-33
#SBATCH --cpus-per-task=10
#SBATCH --mem=100G

set -euo pipefail

# This script assembles reads from the same subject sampled at different timepoints (co-assembly)

# Define variables
#===========================================================================
project_dir="$SCRATCH/PRJEB76307_MGX"
sample_dir="${project_dir}/fastp_bt2_qc/bt2_out" # This directory contains 66 sample directories containing paired-end reads R1 and R2 (after removing reads mapped to the human genome)
scripts_dir="$SCRATCH/castalagin_stool_metagenomics/PRJEB76307_metagenomics" # Scripts from repository

# Create mehahit output directory
megahit_dir="${project_dir}/megahit_co_out"
mkdir -p "${megahit_dir}"
#===========================================================================

# Build a list of subject_ids for the co-assembly
#===========================================================================

# Build subject list on the first instance of the job array
if [[ ${SLURM_ARRAY_TASK_ID} -eq 1 ]]; then
    echo "Building a list of subjects"
    ls "${sample_dir}" | sed 's/_.*//' | sort -u > "${scripts_dir}/subject_ids.txt"
fi

# Short delay so other tasks don't try to read before the subject_ids file exists
sleep 5

# Get subject_id for this SLURM task
subject_id=$(sed -n "${SLURM_ARRAY_TASK_ID}p" subject_ids.txt)
echo "SLURM task ${SLURM_ARRAY_TASK_ID} | Subject: $subject_id"

# Now get timepoint directories
time_dirs=$(ls -d ${sample_dir}/${subject_id}_* 2>/dev/null)

if [[ -z "$time_dirs" ]]; then
    echo "ERROR: No directories found for subject $subject_id"
    exit 1
fi

echo "Timepoint directories: $time_dirs"

# Get the reads from each subject at both timepoints - these will be used in the co-assemblies
R1_files=$(find $time_dirs -type f -name "*unaligned_R1*.fastq.gz" | tr '\n' ',' | sed 's/,$//')
R2_files=$(find $time_dirs -type f -name "*unaligned_R2*.fastq.gz" | tr '\n' ',' | sed 's/,$//')

if [[ -z "$R1_files" || -z "$R2_files" ]]; then
    echo "ERROR: Missing R1 or R2 files for subject $subject_id"
    exit 1
fi

echo "R1: $R1_files"
echo "R2: $R2_files"
#===========================================================================

# Load modules
module load megahit/1.2.9 StdEnv/2023

# Run megahit
megahit -1 $R1_files -2 $R2_files \
--presets meta-sensitive \
--continue \
--min-contig-len 500 \
-t ${SLURM_CPUS_PER_TASK} \
--out-dir "${megahit_dir}/${subject_id}"

# Rename megahit output
mv "${megahit_dir}/${subject_id}/final.contigs.fa" "${megahit_dir}/${subject_id}/${subject_id}_final.contigs.fa"

echo "Finished running megahit for $subject_id"

echo "Starting prodigal workflow from megahit co-assembly"

# Load modules
module load prodigal/2.6.3

# Define variables for the input and output directories
#============================================================================
# Output from megahit becomes input for prodigal
contig_dir="${megahit_dir}/${subject_id}"
prodigal_dir="${project_dir}/prodigal_co_out"
mkdir -p "$prodigal_dir/${subject_id}"
#============================================================================

# Run prodigal on the contigs
# Uses the Standard Bacteria/Archaea translation table (11)
prodigal -i "${contig_dir}/${subject_id}_final.contigs.fa" \
-p meta \
-g 11 \
-a "${prodigal_dir}/${subject_id}/${subject_id}_prodigal_proteins.faa" \
-d "${prodigal_dir}/${subject_id}/${subject_id}_prodigal_genes.fna" \
-o "${prodigal_dir}/${subject_id}/${subject_id}_prodigal_annot.gff"

echo "Finished running prodigal on $subject_id"
