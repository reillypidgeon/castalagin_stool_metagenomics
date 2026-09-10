#!/usr/bin/env bash

#SBATCH --job-name=diamond_uhgp
#SBATCH --output=%x_%A_%a.out
#SBATCH --error=%x_%A_%a.err
#SBATCH --time=00:30:00
#SBATCH --array=0-32
#SBATCH --cpus-per-task=8
#SBATCH --mem=48G

set -euo pipefail

# The purpose of this workflow is to look for matches to known proteins
# The top hits from the query vs. Prodigal-predicted proteins are then searched against the Unified Human Gastrointestinal proteome (UHGP) to assign preliminary taxonomy 
# According to the GTDB r202

# Define variables
#===========================================================================
project_dir="$SCRATCH/PRJEB76307_MGX"
scripts_dir="$SCRATCH/castalagin_stool_metagenomics/PRJEB76307_metagenomics" # Scripts from repository
prodigal_dir="${project_dir}/prodigal_co_out"

# Set the diamond tool thresholds
min_seq_id=60 # Could filter more stringently afterwards
min_coverage=60 # Must cover most of the subject (predicted proteins)
k_value=0   # Unlimited hits per query per sample

# Create output directory for the initial diamond output
diamond_dir="${project_dir}/diamond_co_out"
mkdir -p "${diamond_dir}"
#===========================================================================

# Build array of directories to extract sample_id and read paths
#===========================================================================
dirs=(${prodigal_dir}/*/)
protein_dir=${dirs[$SLURM_ARRAY_TASK_ID]}
sample_id=$(basename "$protein_dir")

# Define locations of proteins from prodigal output and query sequences
proteins=${protein_dir}${sample_id}_prodigal_proteins.faa
query="${scripts_dir}/queries.faa"

db_prefix="${diamond_dir}/${sample_id}_prot_db"
hits_tsv="${diamond_dir}/${sample_id}_hits.tsv"
#===========================================================================

# Checks and cleanup
#===========================================================================
# As a preventative measure, remove all * (stops) from the proteins fasta
proteins_clean="${protein_dir}${sample_id}_prodigal_proteins_no_stop.faa"

# Strip trailing stop codons once from the original protein FASTA and produce a new (cleaned) FASTA
if [ ! -f "${proteins_clean}" ]; then
  sed 's/\*$//' "$proteins" > "${proteins_clean}"
fi

# Look for the query file
if [ ! -f "$query" ]; then
  echo "ERROR: queries.faa not found"
  exit 2
fi

# Look for the cleaned Prodigal protein FASTA file for the given sample ID
if [ ! -f "${proteins_clean}" ]; then
  echo "WARNING: ${proteins_clean} not found for sample $sample_id; skipping"
  exit 0
fi

# Load the required modules for diamond
module load diamond/2.1.11 StdEnv/2023 python/3.13.2
echo "Modules loaded"

# Build the DIAMOND DB (if it doesn't already exist)
if [ ! -f "${db_prefix}.dmnd" ]; then
  echo "Building DIAMOND DB for $sample_id"
  diamond makedb \
    --in "$proteins_clean" \
    -d "$db_prefix"
fi
#===========================================================================

# Now run DIAMOND using the DB
echo "Running DIAMOND (blastp mode) for $sample_id"

diamond blastp \
  -q "$query" \
  -d "${db_prefix}" \
  -o "${hits_tsv}" \
  --outfmt 6 qseqid sseqid pident ppos length qlen slen qstart qend sstart send evalue bitscore full_qseq full_sseq \
  --id ${min_seq_id} \
  --subject-cover ${min_coverage} \
  -k ${k_value} \
  --threads ${SLURM_CPUS_PER_TASK}

echo "Sample ${sample_id} finished. Hits: $(wc -l < "${hits_tsv}" 2>/dev/null || echo 0)"

### Stopped here - need to add the UHGP portion





# Define variables for the search against the UHGP
#===========================================================================
# Create output directory for diamond_uhgp output
diamond_uhgp_dir="${project_dir}/diamond_uhgp_out"
mkdir -p "${diamond_uhgp_dir}"
