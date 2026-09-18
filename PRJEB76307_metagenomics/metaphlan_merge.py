#!/usr/bin/env python3

import pandas as pd
import glob
import os

# Create an empty array
dfs = []

# Loop through the MetaPhlAn output directory and add the sample_id to the relative abundance column for each GTDB results table
for file in glob.glob("*_GTDB.tsv"):
    sample = os.path.basename(file).replace("_metaphlan_out_GTDB.txt", "")
    df = pd.read_csv(file, sep="\t", comment="#", header=None, names=["GTDB_taxonomy", sample], index_col=0)
    dfs.append(df)

# Combine all dfs
merged_df = pd.concat(dfs, axis=1).fillna(0)

# Sort sample columns alphabetically
merged_df_sorted = merged_df.reindex(sorted(merged_df.columns), axis=1)

# Write output to TSV file
merged_df_sorted.to_csv("merged_metaphlan_GTDB.tsv", sep="\t")

print("Merge finished in python")
