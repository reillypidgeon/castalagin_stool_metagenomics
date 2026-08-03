#!/bin/bash

#SBATCH --job-name=diamond_uhgp
#SBATCH --output=%x.out
#SBATCH --error=%x.err
#SBATCH --time=02:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=48G

date

# The purpose of this workflow is to look for matches to known proteins
# The top hits are then searched against the Unified Human Gastrointestinal Proteome (UHGP) to assign preliminary taxonomy (according to the GTDB r202)

# Load the required modules for diamond
module load diamond/2.1.11 StdEnv/2023 python/3.13.2
echo "Modules loaded"

# Define variables
#===========================================================================
PRODIGAL_DIR="prodigal_out"
SAMPLE_ID="MO67"
export SAMPLE_ID
QUERY="RP01-94_queries.faa"
PROT="$PRODIGAL_DIR/${SAMPLE_ID}_prodigal_proteins.faa"

# Create output directory for diamond output
DIAMOND_DIR="diamond_out"
mkdir -p $DIAMOND_DIR
export DIAMOND_DIR

# Prefix and output table file names
DB_PREFIX="${DIAMOND_DIR}/${SAMPLE_ID}_prot_db"
HITS_TSV="${DIAMOND_DIR}/${SAMPLE_ID}_hits.tsv"

# DIAMOND tool thresholds
MIN_ID=60 # Could filter more stringently afterwards
S_COV=60 # Must cover most of the subject (predicted proteins)
KVAL=0   # unlimited hits per query per sample
#===========================================================================

# Checks
#===========================================================================
# As a preventative measure, remove all * (stops) from the PROT fasta
PROT_CLEAN="$PRODIGAL_DIR/${SAMPLE_ID}_prodigal_proteins_no_stop.faa"

if [ ! -f "$PROT_CLEAN" ]; then
  sed 's/\*$//' "$PROT" > "$PROT_CLEAN"
fi

# Look for the cleaned prodigal protein fasta file for the given sample ID
if [ ! -f "$PROT_CLEAN" ]; then
  echo "WARNING: $PROT_CLEAN not found; skipping"
  exit 0
fi

# Look for the query
if [ ! -f "$QUERY" ]; then
  echo "ERROR: query file not found"
  exit 2
fi

# Build the diamond DB (if it doesn't already exist)
if [ ! -f "${DB_PREFIX}.dmnd" ]; then
  echo "Building diamond DB"
  diamond makedb \
    --in "$PROT_CLEAN" \
    -d "$DB_PREFIX"
fi
#===========================================================================

# Now run DIAMOND using the built diamond DB
echo "Running DIAMOND"

diamond blastp \
  -q "$QUERY" \
  -d "$DB_PREFIX" \
  -o "$HITS_TSV" \
  --outfmt 6 qseqid sseqid pident ppos length qlen slen qstart qend sstart send evalue bitscore full_qseq full_sseq \
  --id "$MIN_ID" \
  --subject-cover "$S_COV" \
  -k "$KVAL" \
  --threads "$SLURM_CPUS_PER_TASK"

echo "Sample finished. Hits: $(wc -l < "$HITS_TSV" 2>/dev/null || echo 0)"

# Now annotate the resulting diamond output table
module scipy-stack/2025a
echo "Modules loaded"

# Generate a best hits table
python3 << 'EOF'
import pandas as pd
from pathlib import Path
import glob
import os

# Get the sample_id
diamond_dir = os.getenv("DIAMOND_DIR")
sample_id = os.getenv("SAMPLE_ID")

df_path = f"{diamond_dir}/{sample_id}_hits.tsv"

# Import the dataframe and add titles to the columns
df = pd.read_csv(df_path, sep="\t", header=None,
	names=["qseqid","sseqid","pident","ppos","length","qlen","slen",
  "qstart","qend","sstart","send","evalue","bitscore","full_qseq","full_sseq"])

# Filter by best hit(s) and keep the first instance of a best hit (by sseqid) if there's a tie
best_hits_df = df.loc[df.groupby('sseqid')['pident'].idxmax()]
best_hits_df = best_hits_df.reset_index(drop=True)

# Export table to TSV
best_hits_df.to_csv(f"{diamond_dir}/{sample_id}_best_hits.tsv", sep="\t", index=False)

# Now generate a fasta file from the best hits dataframe
# The sseqid and qseqid will be joined by a dash in the fasta headers
with open(f"{diamond_dir}/{sample_id}_best_hits.fasta", "w") as fasta:
	for _, row in best_hits_df.iterrows():
		fasta.write(f">{row["sseqid"]}-{row["qseqid"]}\n")
		fasta.write(f"{row["full_sseq"]}\n")

print(f"Created fasta output for {sample_id}")
EOF

#===========================================================================
# Create output directory for diamond_uhgp output
DIAMOND_UHGP_DIR="diamond_uhgp_out"
mkdir -p $DIAMOND_UHGP_DIR

# Set the DIAMOND tool input, database, and output file names
QUERY="$DIAMOND_DIR/${SAMPLE_ID}_best_hits.fasta"
DIAMOND_DB="$SCRATCH/uhgp" # see castalagin_stool_metagenomics/download_scipts/uhgp_download.sh
HITS_TSV="$DIAMOND_UHGP_DIR/all_hits_uhgp-100.tsv"
#===========================================================================

# Copy the UHGP metadata to the output directory
# Metadata copied and renamed from: 
# https://ftp.ebi.ac.uk/pub/databases/metagenomics/mgnify_genomes/human-gut/v2.0/genomes-all_metadata.tsv	

if [ ! -f "$DIAMOND_UHGP_DIR/uhgp_genomes_all_metadata.tsv" ]; then
    echo "UHGP metadata file does not exist. Copying from ${DIAMOND_DB}"
    cp $DIAMOND_DB/uhgp_genomes_all_metadata.tsv $DIAMOND_UHGP_DIR
fi

# Run DIAMOND using the uhgp-100 DB
echo "Running DIAMOND"

diamond blastp \
  -q "$QUERY" \
  -d "$DIAMOND_DB/uhgp-100" \
  -o "$HITS_TSV" \
  --outfmt 6 qseqid sseqid pident ppos length qlen slen qstart qend sstart send evalue bitscore full_qseq full_sseq \
  --id $MIN_ID \
  -k $KVAL \
  --threads $SLURM_CPUS_PER_TASK

echo "Finished search against UHGP-100"


# Annotate the UHGP output table
cd $DIAMOND_UHGP_DIR

python3 << 'EOF'
import pandas as pd
from pathlib import Path

# Import the dataframes and add titles to the columns
df = pd.read_csv('all_hits_uhgp-100.tsv', sep='\t', header=None,
	names=["qseqid","sseqid","pident","ppos","length","qlen","slen","qstart","qend","sstart","send","evalue","bitscore","full_qseq","full_sseq"])

metadata = pd.read_csv('uhgp_genomes_all_metadata.tsv', sep='\t')

# Extract the UHGP genome reference from the sseqid (protein identity)
df['Genome'] = df['sseqid'].str.split('_').str[0]

# Extract the contig_id from the qseqqid (this corresponds to the MO67_best_hits.fasta headers according to the following format: k141_77377_1-Hh_oxido)
df[['contig_id', 'closest_query']] = df['qseqid'].str.split('-', n=1, expand=True)

# Merge the metadata with the individual dataframes from the hits lists
df_merge = pd.merge(df, metadata, left_on='Genome', right_on='Genome')

# Export tables to CSV
df_merge.to_csv('all_hits_uhgp-100_metadata.tsv', sep="\t", index=False)

# Filter by best hit(s) and keep the first instance of a best hit if there's a tie
best_hits_df_merge = df_merge.loc[df_merge.groupby('qseqid')['pident'].idxmax()]
best_hits_df_merge = best_hits_df_merge.reset_index(drop=True)

# Export tables to CSV
best_hits_df_merge.to_csv('best_hits_uhgp-100_metadata.tsv', sep="\t", index=False)

EOF

echo "Finished merging"
date

cd ..

python3 string_pattern_mapping.py "$DIAMOND_UHGP_DIR/best_hits_uhgp-100_metadata.tsv" "pattern_mapping.tsv" "$DIAMOND_UHGP_DIR/best_hits_uhgp-100_metadata_operon.tsv"

echo "Finished annotating the UHGP best hits table with gene and operon information"
