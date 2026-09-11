#!/usr/bin/env python3

import pandas as pd
import glob
import os

print("Collecting per-sample diamond TSVs...")

# Find all *_hits.tsv files in the current directory
hits_tables = glob.glob("*_hits.tsv")

# Check if tables are found
if len(hits_tables) == 0:
    raise FileNotFoundError("No *_hits.tsv files found.")

# Create an empty array
dfs = []

# Loop through the hits tables, extract the sample_id, add as a column, then populate the dfs array
for f in hits_tables:
    # Sample ID = file prefix
    sample = os.path.basename(f).replace("_hits.tsv", "")
    print(f"Loading: {f} (sample: {sample})")
    
    df = pd.read_csv(f, sep="\t", header=None,
        names=["qseqid","sseqid","pident","ppos","length","qlen","slen","qstart","qend","sstart","send","evalue","bitscore","full_qseq","full_sseq"])
    
    df["sample"] = sample
    col = df.pop("sample")
    df.insert(2, "sample", col)
    dfs.append(df)

# Merge everything
print("Concatenating tables...")
all_hits_df = pd.concat(dfs, ignore_index=True)
print(all_hits_df)

# Filter by best hit(s) and keep the first instance of a best hit (by sseqid) if there's a tie
best_hits_df = all_hits_df.loc[all_hits_df.groupby(["sample", "sseqid"])["pident"].idxmax()]
best_hits_df = best_hits_df.reset_index(drop=True)

# Export table to TSV
best_hits_df.to_csv("diamond_co_best_hits.tsv", sep="\t", index=False)

# Now generate a FASTA file from the merged best hits dataframe
# The sseqid, sample, and qseqid will be joined by dashes in the FASTA headers
with open("diamond_co_best_hits.fasta", "w") as fasta:
	for _, row in best_hits_df.iterrows():
		fasta.write(f">{row["sseqid"]}-{row["sample"]}-{row["qseqid"]}\n")
		fasta.write(f"{row["full_sseq"]}\n")

print(f"Created fasta output.")
