#!/bin/bash

#SBATCH --job-name=MO67_diamond
#SBATCH --output=%x.out
#SBATCH --error=%x.err
#SBATCH --time=00:30:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=48G

date

# Load the required modules for diamond
module load diamond/2.1.11 StdEnv/2023 python/3.13.2
echo "Modules loaded"

# These are the directory variables and sample_id
OUT_DIR=$SCRATCH/RP01-94_MO67_MGX # General output directory for each tool
PRODIGAL_DIR=$OUT_DIR/prodigal_out
SAMPLE_ID="MO67_A-D"

# Create output directory for diamond output
DIAMOND_OUT=$OUT_DIR/diamond_out
mkdir -p $DIAMOND_OUT

# Define locations of proteins from prodigal output and query sequences
PROT=$PRODIGAL_DIR/${SAMPLE_ID}_prodigal_proteins.faa
QUERY=$OUT_DIR/RP01-94_queries.faa # This fasta contains the sequences of interest to look for in each protein set from prodigal

DB_PREFIX="${DIAMOND_OUT}/MO67_prot_db"
HITS_TSV="${DIAMOND_OUT}/MO67_hits.tsv"

# As a preventative measure, remove all * (stops) from the PROT fasta
PROT_CLEAN="$PRODIGAL_DIR/${SAMPLE_ID}_prodigal_proteins_no_stop.faa"

# Strip trailing stop codons once from the original protein fasta and produce a new (cleaned) fasta
if [ ! -f "$PROT_CLEAN" ]; then
  sed 's/\*$//' "$PROT" > "$PROT_CLEAN"
fi

# Look for the query file
if [ ! -f "$QUERY" ]; then
  echo "ERROR: queries file not found"
  exit 2
fi

# Look for the cleaned prodigal protein fasta file for the given sample ID
if [ ! -f "$PROT_CLEAN" ]; then
  echo "WARNING: $PROT_CLEAN not found; skipping"
  exit 0
fi

# Set the DIAMOND tool thresholds
MIN_ID=60 # Could filter more stringently afterwards
S_COV=60 # Must cover most of the subject (predicted proteins)
KVAL=0   # unlimited hits per query per sample - could limit to a certain number if needed

# Build the DIAMOND DB (if it doesn't already exist)
if [ ! -f "${DB_PREFIX}.dmnd" ]; then
  echo "Building DIAMOND DB for MO67"
  diamond makedb \
    --in "$PROT_CLEAN" \
    -d "$DB_PREFIX"
fi

# Now run DIAMOND using the DB
echo "Running DIAMOND (blastp mode) for MO67"

diamond blastp \
  -q "$QUERY" \
  -d "$DB_PREFIX" \
  -o "$HITS_TSV" \
  --outfmt 6 qseqid sseqid pident ppos length qlen slen qstart qend sstart send evalue bitscore full_qseq full_sseq \
  --id $MIN_ID \
  --subject-cover $S_COV \
  -k $KVAL \
  --threads $SLURM_CPUS_PER_TASK

echo "Sample finished. Hits: $(wc -l < "$HITS_TSV" 2>/dev/null || echo 0)"
