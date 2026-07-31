#!/bin/bash

#SBATCH --job-name=MO67_diamond_uhgp
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
echo "Running DIAMOND"

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

# Now annotate the resulting diamond output table
module scipy-stack/2025a
echo "Modules loaded"

# These are the directory variables for samples and the newly created output
HITS_DIR=$OUT_DIR/diamond_out
cd $HITS_DIR

# Generate a best hits table from MO67_hits.tsv
python3 << 'EOF'
import pandas as pd
from pathlib import Path

# Import the dataframe and add titles to the columns
df = pd.read_csv('MO67_hits.tsv', sep='\t', header=None,
	names=["qseqid","sseqid","pident","ppos","length","qlen","slen",
  "qstart","qend","sstart","send","evalue","bitscore","full_qseq","full_sseq"])

# Filter by best hit(s) and keep the first instance of a best hit (by sseqid) if there's a tie
best_hits_df = df.loc[df.groupby('sseqid')['pident'].idxmax()]
best_hits_df = best_hits_df.reset_index(drop=True)

# Export table to TSV
best_hits_df.to_csv('MO67_best_hits.tsv', sep="\t", index=False)

# Now generate a fasta file from the best hits dataframe
with open("MO67_best_hits.fasta", "w") as fasta:
	for _, row in best_hits_df.iterrows():
		fasta.write(f">{row["sseqid"]}-{row["qseqid"]}\n")
		fasta.write(f"{row["full_sseq"]}\n")

print(f"Created fasta output.")
EOF

# Create output directory for diamond output
DIAMOND_OUT=$OUT_DIR/diamond_uhgp_out
mkdir -p $DIAMOND_OUT

# Set the DIAMOND tool thresholds
MIN_ID=60 # Could filter more stringently afterwards
KVAL=0   # unlimited hits per query per sample - could limit to a certain number if needed

# Set the DIAMOND tool input, database, and output file names
QUERY="$HITS_DIR/MO67_best_hits.fasta"
DIAMOND_DB="$SCRATCH/uhgp" # Note that this DB has already been created (see repository download_scipts/uhgp_download.sh)
HITS_TSV="$DIAMOND_OUT/all_hits_uhgp-100.tsv"

# Copy the UHGP metadata to the output directory
# Metadata copied and renamed from: https://ftp.ebi.ac.uk/pub/databases/metagenomics/mgnify_genomes/human-gut/v2.0/genomes-all_metadata.tsv	

if [ ! -f "$DIAMOND_OUT/uhgp_genomes_all_metadata.tsv" ]; then
    echo "UHGP metadata file does not exist. Copying from ${DIAMOND_DB}"
    cp $DIAMOND_DB/uhgp_genomes_all_metadata.tsv $DIAMOND_OUT
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

echo "Starting merge"

cd $DIAMOND_OUT

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
