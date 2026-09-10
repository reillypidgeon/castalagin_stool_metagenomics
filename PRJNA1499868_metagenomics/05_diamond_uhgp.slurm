#!/usr/bin/env bash

#SBATCH --job-name=diamond_uhgp
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
#SBATCH --time=02:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=48G

set -euo pipefail

# The purpose of this workflow is to look for matches to known proteins
# The top hits from the query vs. Prodigal-predicted proteins are then searched against the Unified Human Gastrointestinal proteome (UHGP) to assign preliminary taxonomy 
# According to the GTDB r202

# Define variables
#===========================================================================
project_dir="$SCRATCH/PRJNA1499868_MGX"
scripts_dir="$SCRATCH/castalagin_stool_metagenomics/PRJNA1499868_metagenomics" # Scripts from repository
sample_id="MO67"
prodigal_dir="${project_dir}/prodigal_out"

query="${scripts_dir}/RP01-94_queries.faa"
proteins="${prodigal_dir}/${sample_id}_prodigal_proteins.faa"

# Create output directory for diamond output
diamond_dir="${project_dir}/diamond_out"
mkdir -p "${diamond_dir}"

# Prefix and output table file names
db_prefix="${diamond_dir}/${sample_id}_proteins_db"
hits_tsv="${diamond_dir}/${sample_id}_hits.tsv"

# diamond tool thresholds
min_id=60 # Could filter more stringently afterwards
s_cov=60 # Must cover most of the subject (predicted proteins)
k_val=0   # unlimited hits per query per sample
#===========================================================================

# Checks and cleanup
#===========================================================================
# As a preventative measure, remove all * (stops) from the proteins fasta
proteins_clean="${prodigal_dir}/${sample_id}_prodigal_proteins_no_stop.faa"

if [[ ! -f "${proteins_clean}" ]]; then
  sed 's/\*$//' "$proteins" > "${proteins_clean}"
fi

# Look for the cleaned prodigal proteins FASTA file for the given sample ID
if [[ ! -f "${proteins_clean}" ]]; then
  echo "WARNING: ${proteins_clean} not found; skipping"
  exit 0
fi

# Look for the query
if [[ ! -f "$query" ]]; then
  echo "ERROR: query file not found"
  exit 2
fi

# Load the required modules for diamond and the Python script
module load diamond/2.1.11 StdEnv/2023 python/3.13.2

# Build the diamond database (if it doesn't already exist)
if [[ ! -f "${db_prefix}.dmnd" ]]; then
  echo "Building diamond database"
  diamond makedb \
    --in "${proteins_clean}" \
    -d "${db_prefix}"
fi
#===========================================================================

# Now run diamond using the built diamond database
echo "Running diamond: queries FASTA file against prodigal-predicted proteins"

diamond blastp \
  -q "$query" \
  -d "${db_prefix}" \
  -o "${hits_tsv}" \
  --outfmt 6 qseqid sseqid pident ppos length qlen slen qstart qend sstart send evalue bitscore full_qseq full_sseq \
  --id "${min_id}" \
  --subject-cover "${s_cov}" \
  -k "${k_val}" \
  --threads "${SLURM_CPUS_PER_TASK}"

echo "Sample finished. Hits: $(wc -l < "${hits_tsv}" 2>/dev/null || echo 0)"

# Now annotate the resulting diamond output table
module load scipy-stack/2026a

# Export variables
export diamond_dir
export sample_id

# Generate a best hits table and a best-hits FASTA file in the diamond_out directory
python3 "${scripts_dir}/uhgp_best_hits.py"

# Define variables for the search against the UHGP
#===========================================================================
# Create output directory for diamond_uhgp output
diamond_uhgp_dir="${project_dir}/diamond_uhgp_out"
mkdir -p "${diamond_uhgp_dir}"

# Set the diamond tool input, database, and output file names
query="${diamond_dir}/${sample_id}_best_hits.fasta"
diamond_db="$SCRATCH/uhgp" # See castalagin_stool_metagenomics/database_downloads/02_uhgp_download.sh
hits_tsv="${diamond_uhgp_dir}/all_hits_uhgp-100.tsv"
metadata="${diamond_db}/uhgp_genomes_all_metadata.tsv"
#===========================================================================

# Run diamond using the uhgp-100 database
echo "Running diamond: previously-generated best_hits FASTA against the UHGP"

diamond blastp \
  -q "$query" \
  -d "${diamond_db}/uhgp-100" \
  -o "${hits_tsv}" \
  --outfmt 6 qseqid sseqid pident ppos length qlen slen qstart qend sstart send evalue bitscore full_qseq full_sseq \
  --id ${min_id} \
  -k ${k_val} \
  --threads ${SLURM_CPUS_PER_TASK}

echo "Finished search against the UHGP"

# Annotate the UHGP output table and extract the best hits from the diamond search
export diamond_uhgp_dir
export hits_tsv
export metadata

python3 "${scripts_dir}/uhgp_annotate_tables.py"

echo "Finished merging the diamond UHGP table with UHGP metadata"

# Match patterns (in the best-hits table) from query FASTA headers to extract operon and gene names based on the pattern_mapping.tsv file
python3 "${scripts_dir}/string_pattern_mapping.py" "${diamond_uhgp_dir}/best_hits_uhgp-100_metadata.tsv" "${scripts_dir}/pattern_mapping.tsv" "${diamond_uhgp_dir}/best_hits_uhgp-100_metadata_operon.tsv"

echo "Finished annotating the UHGP best hits table with gene and operon information"
