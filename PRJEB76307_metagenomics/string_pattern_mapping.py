#!/usr/bin/env python3

import sys
import pandas as pd

print("Python executable:", sys.executable)
print("System argument list", sys.argv)

# Script usage
if len(sys.argv) != 4:
    print(f"Usage: {sys.argv[0]} <results_table.tsv> <pattern_mapping.tsv> <output.tsv>")
    print()
    print("Arguments:")
    print("  results_table.tsv    TSV containing the qseqid column that you want to match to")
    print("  pattern_mapping.tsv  TSV containing the pattern column and annotations")
    print("  output.tsv           Output TSV file")
    sys.exit(1)

# Define the path variables according to the input and print
results_table = sys.argv[1]
pattern_table = sys.argv[2]
output_file = sys.argv[3]

print(results_table)
print(pattern_table)
print(output_file)

# Check that the inputs are strings (paths to each file)
print(type(results_table))
print(type(pattern_table))
print(type(output_file))

# Read both the results and patterns tables
results = pd.read_csv(results_table, sep="\t") # We care about the qseqid column here
patterns = pd.read_csv(pattern_table, sep="\t") # We want to match a portion of the qseqid in results to the Pattern column in this table 

# To be safe, convert all the column headers (names) to lowercase
results.columns = results.columns.str.lower()
patterns.columns = patterns.columns.str.lower()

print(results)
print(patterns)

# Add empty columns for annotations
annotation_cols = [c for c in patterns.columns if c != "pattern"]
for col in annotation_cols:
    results[col] = None

print(results)

# Match patterns
for _, row in patterns.iterrows():
    mask = results["qseqid"].str.contains(row["pattern"], regex=False, na=False)
    results.loc[mask, annotation_cols] = row[annotation_cols].values

print(results)

# Write output (make sure to add a .tsv extension if it's not already there)
if not output_file.endswith((".tsv", ".txt")):
    output_file += ".tsv"
results.to_csv(output_file, sep="\t", index=False)
