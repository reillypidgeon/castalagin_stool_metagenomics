#!/usr/bin/env python3

import pandas as pd
from pathlib import Path
import os

# Get the sample_id
diamond_uhgp_dir = os.getenv("diamond_uhgp_dir")
hits_tsv = os.getenv("hits_tsv")
metadata = os.getenv("metadata")

# Import the dataframes and add titles to the columns
df = pd.read_csv(hits_tsv, sep="\t", header=None,
	names=["qseqid","sseqid","pident","ppos","length","qlen","slen","qstart","qend","sstart","send","evalue","bitscore","full_qseq","full_sseq"])

metadata_df = pd.read_csv(metadata, sep="\t")

# Extract the UHGP genome reference from the sseqid (protein identity)
df["Genome"] = df["sseqid"].str.split("_").str[0]

# Extract the contig_id from the qseqqid (this corresponds to the MO67_best_hits.fasta headers according to the following format: k141_77377_1-Hh_oxido)
df[["contig_id", "closest_query"]] = df["qseqid"].str.split("-", n=1, expand=True)

# Merge the metadata with the individual dataframes from the hits lists
df_merge = pd.merge(df, metadata_df, left_on="Genome", right_on="Genome")

# Filter by best hit(s) and keep the first instance of a best hit if there's a tie
best_hits_df_merge = df_merge.loc[df_merge.groupby("qseqid")["pident"].idxmax()]
best_hits_df_merge = best_hits_df_merge.reset_index(drop=True)

# Export tables to TSV
df_merge.to_csv(f"{diamond_uhgp_dir}/all_hits_uhgp-100_metadata.tsv", sep="\t", index=False)
best_hits_df_merge.to_csv(f"{diamond_uhgp_dir}/best_hits_uhgp-100_metadata.tsv", sep="\t", index=False)
