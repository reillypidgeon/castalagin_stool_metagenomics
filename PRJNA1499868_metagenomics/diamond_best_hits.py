#!/usr/bin/env python3

import pandas as pd
import os

# Get the sample_id
diamond_dir = os.getenv("diamond_dir")
sample_id = os.getenv("sample_id")

df_path = f"{diamond_dir}/{sample_id}_hits.tsv"

# Import the dataframe and add titles to the columns
df = pd.read_csv(df_path, sep="\t", header=None,
	names=["qseqid","sseqid","pident","ppos","length","qlen","slen","qstart","qend","sstart","send","evalue","bitscore","full_qseq","full_sseq"])

# Filter by best hit(s) and keep the first instance of a best hit (by sseqid) if there's a tie
best_hits_df = df.loc[df.groupby('sseqid')['pident'].idxmax()]
best_hits_df = best_hits_df.reset_index(drop=True)

# Export table to TSV
best_hits_df.to_csv(f"{diamond_dir}/{sample_id}_best_hits.tsv", sep="\t", index=False)

# Now generate a FASTA file from the best hits dataframe
# The sseqid and qseqid will be joined by a dash in the FASTA headers
with open(f"{diamond_dir}/{sample_id}_best_hits.fasta", "w") as fasta:
	for _, row in best_hits_df.iterrows():
		fasta.write(f">{row["sseqid"]}-{row["qseqid"]}\n")
		fasta.write(f"{row["full_sseq"]}\n")

print(f"Created fasta output for {sample_id}")
