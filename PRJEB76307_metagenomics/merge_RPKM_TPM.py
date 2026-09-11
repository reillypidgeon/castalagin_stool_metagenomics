#!/usr/bin/env python3

import pandas as pd
from pathlib import Path

base_dir = Path("fc_ra_out")

dfs = []

for tsv in base_dir.glob("**/*.tsv"):
	df = pd.read_csv(tsv, sep="\t")
	df["sample"] = tsv.parent.name
	dfs.append(df)

merged_df = pd.concat(dfs, ignore_index=True)
merged_df[["gene_id", "counts", "length_bp", "RPKM", "TPM", "subject", "sample"]].to_csv("merged_RPKM_TPM.tsv", sep="\t", index=False)
