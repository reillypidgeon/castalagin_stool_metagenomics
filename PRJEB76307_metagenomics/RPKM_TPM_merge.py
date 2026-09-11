#!/usr/bin/env python3

import pandas as pd
import glob
import glob

# Define the base directory based on the exported variable
base_dir = os.getenv("fc_ra_dir")

# Create an empty array
dfs = []

# Loop through the TSV files within subdirectories of the base_dir and append to the dfs array
for tsv in base_dir.glob("**/*.tsv"):
	df = pd.read_csv(tsv, sep="\t")
	df["sample"] = tsv.parent.name
	dfs.append(df)

# Combine all dfs
merged_df = pd.concat(dfs, ignore_index=True)

# Write output to TSV file
merged_df[["gene_id", "counts", "length_bp", "RPKM", "TPM", "subject", "sample"]].to_csv(f"{base_dir}/merged_RPKM_TPM.tsv", sep="\t", index=False)
