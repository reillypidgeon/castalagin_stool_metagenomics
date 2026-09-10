#!/usr/bin/env python3

import sys
import pandas as pd

print("Python executable:", sys.executable)
print("System argument list", sys.argv)

# Define the path variables according to the input and print
fc_file = sys.argv[1]
len_file = sys.argv[2]
out_file = sys.argv[3]
patient_id = sys.argv[4]
sample_id = sys.argv[5]

print(fc_file)
print(len_file)
print(out_file)
print(patient_id)
print(sample_id)

# Check that the inputs are strings (paths to each file)
print(type(fc_file))
print(type(len_file))
print(type(out_file))
print(type(patient_id))
print(type(sample_id))

# Load featureCounts table
fc = pd.read_csv(fc_file, sep="\t", comment="#")

count_col = fc.columns[-1]
fc = fc[["Geneid", count_col]]
fc.columns = ["GeneID", "Counts"]

# Load gene lengths
lengths = pd.read_csv(len_file, sep="\t", header=None, names=["GeneID", "Length_bp"])

# Merge by GeneID
df = fc.merge(lengths, on="GeneID", how="inner")

# Total mapped reads (used for RPKM)
total_counts = df["Counts"].sum()

# Calculate RPKM (reads per kb per million mapped reads)
df["RPKM"] = (df["Counts"] * 1e9) / (df["Length_bp"] * total_counts)

# Calculate TPM (transcripts per million)
df["Length_kb"] = df["Length_bp"] / 1000
df["RPK"] = df["Counts"] / df["Length_kb"]
rpk_sum = df["RPK"].sum()
df["TPM"] = (df["RPK"] / rpk_sum) * 1e6

# Add the patient and sample metadata to each dataframe
df["patient"] = patient_id
df["sample"] = sample_id
# Output
df[["GeneID", "Counts", "Length_bp", "RPKM", "TPM", "patient", "sample"]].to_csv(out_file, sep="\t", index=False)

print("Conversion finished")
