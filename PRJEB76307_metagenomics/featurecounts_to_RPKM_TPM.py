#!/usr/bin/env python3

import sys
import pandas as pd

print("Python executable:", sys.executable)
print("System argument list", sys.argv)

# Define the path variables according to the input and print
fc_file = sys.argv[1]
len_file = sys.argv[2]
out_file = sys.argv[3]
subject_id = sys.argv[4]
sample_id = sys.argv[5]

# Load featureCounts table
fc = pd.read_csv(fc_file, sep="\t", comment="#")

# Extract the last column (counts) and rename headers
count_col = fc.columns[-1]
fc = fc[["Geneid", count_col]]
fc.columns = ["gene_id", "counts"]

# Load gene lengths
lengths = pd.read_csv(len_file, sep="\t", header=None, names=["gene_id", "length_bp"])

# Merge by GeneID
df = fc.merge(lengths, on="gene_id", how="inner")

# Total mapped reads (used for RPKM)
total_counts = df["counts"].sum()

# Calculate RPKM (reads per kb per million mapped reads)
df["RPKM"] = (df["counts"] * 1e9) / (df["length_bp"] * total_counts)

# Calculate TPM (transcripts per million)
df["length_kb"] = df["length_bp"] / 1000
df["RPK"] = df["counts"] / df["length_kb"]
rpk_sum = df["RPK"].sum()
df["TPM"] = (df["RPK"] / rpk_sum) * 1e6

# Add the subject and sample metadata to each dataframe
df["subject"] = subject_id
df["sample"] = sample_id

# Write output to TSV
df[["gene_id", "counts", "length_bp", "RPKM", "TPM", "patient", "sample"]].to_csv(out_file, sep="\t", index=False)

print("Conversion finished")
