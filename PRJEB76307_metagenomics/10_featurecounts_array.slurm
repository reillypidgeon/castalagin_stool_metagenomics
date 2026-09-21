#!/usr/bin/env bash

#SBATCH --job-name=featurecounts
#SBATCH --output=%x_%A_%a.out
#SBATCH --error=%x_%A_%a.err
#SBATCH --time=0:20:00
#SBATCH --array=0-65
#SBATCH --cpus-per-task=8
#SBATCH --mem=100G

set -euo pipefail

# Define common variables
#===========================================================================
project_dir="$SCRATCH/PRJEB76307_MGX"
sample_dir="${project_dir}/bt2_backmap_out" 
scripts_dir="$SCRATCH/castalagin_stool_metagenomics/PRJEB76307_metagenomics" # Scripts from repository
prodigal_dir="${project_dir}/prodigal_co_out"

# Create output directory
fc_dir="${project_dir}/fc_out"
mkdir -p "${fc_dir}"
#===========================================================================

# Build array of directories to extract sample_id and subject_id
#===========================================================================
dirs=(${sample_dir}/*/)
bam_dir=${dirs[${SLURM_ARRAY_TASK_ID}]} # BAM directory of a sample_id based on the array index
sample_id=$(basename "${bam_dir}")
subject_id=$(basename ${bam_dir%_*}) # Extracts before the underscore

# Define BAM file paths
bam="${bam_dir}${sample_id}_bt2_backmap_sorted.bam"
annotations_dir=${prodigal_dir}/${subject_id}

echo "Sample: $sample_id"
echo "Subject: $subject_id"
echo "BAM file: $bam"
#===========================================================================

# Before running featureCounts, extract gene coordinate information and gene lengths from the Prodigal genes FASTA file
#===========================================================================
cd $annotations_dir

# Create a SAF annotation file
awk '
BEGIN { OFS="\t" }
/^>/ {
    # Remove >
    gsub(/^>/, "", $1)

    gene_id = $1
    start   = $3
    end     = $5
    strand  = ($7 == "1") ? "+" : "-"

    # Extract contig name (everything except last _number)
    contig = gene_id
    sub(/_[0-9]+$/, "", contig)

    print gene_id, contig, start, end, strand
}
' "${subject_id}_prodigal_genes.fna" > "${subject_id}_prodigal_annotations.saf"

# Define SAF file path
saf="${annotations_dir}/${subject_id}_prodigal_annotations.saf"

# Create a gene lengths file in the same directory for downstream analyses
awk '
BEGIN { OFS="\t" }
/^>/ {
  if (len) print gene, len
  gene = substr($0,2)
  sub(/ .*/, "", gene)
  len = 0
  next
}
{ len += length($0) }
END { print gene, len }
' "${subject_id}_prodigal_genes.fna" > "${subject_id}_prodigal_gene_lengths.tsv"

# Define gene lengths file path
gene_lengths="${annotations_dir}/${subject_id}_prodigal_gene_lengths.tsv"

cd "${project_dir}"
#===========================================================================

# Run featureCounts in paired-end mode

# Create a new directory based on sample_id
mkdir -p ${fc_dir}/${sample_id}

# Define featureCounts file path
fc_file="${fc_dir}/${sample_id}/${sample_id}_featureCounts.txt"

# Load modules
module load StdEnv/2023 subread/2.0.6 python/3.13.2 scipy-stack/2026a

echo "Running featureCounts"
featureCounts \
    -T ${SLURM_CPUS_PER_TASK} \
    -a ${saf} \
    -F SAF \
    -p \
    -B \
    -C \
    -o "${fc_file}" \
    ${bam}

echo "featureCounts completed. Output written to: ${fc_file}"

# Now convert the featureCounts output to RPKM and TPM values

# Define common variables
#===========================================================================
# Define relative abundance (normalization) output file path
output_file="${fc_ra_dir}/${sample_id}/${sample_id}_fc_ra.tsv"

# Convert to real path to avoid confusion in Python
fc_file=$(realpath "${fc_file}")
gene_lengths=$(realpath "${gene_lengths}")
output_file=$(realpath "${output_file}")

# Create output directory for featureCounts conversion to RPKM and TPM (relative abundance)
fc_ra_dir="${project_dir}/fc_ra_out"
mkdir -p "${fc_ra_dir}/${sample_id}"
#===========================================================================

# Check if gene lengths file is found
if [[ ! -f "${gene_lengths}" ]]; then
  echo "ERROR: Gene length file not found: ${gene_lengths}"
  exit 1
fi

# Run the Python conversion script by taking input from the Unix environment
python3 "${scripts_dir}/featurecounts_to_RPKM_TPM.py" "${fc_file}" "${gene_lengths}" "${output_file}" "${subject_id}" "${sample_id}"

echo "Finished converting ${sample_id} to RPKM and TPM"
