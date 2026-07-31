#!/bin/bash

cd $SCRATCH/RP01-93_CC_CT/RP01-93_CC_CT_analysis/

# Load modules
module load StdEnv/2023 python/3.12.4 scipy-stack/2025a

python << 'EOF'
import pandas as pd
import glob
import os

dfs = []

for file in glob.glob("metaphlan_out/*_GTDB.txt"):
    sample = os.path.basename(file).replace("_metaphlan_out_GTDB.txt", "")
    df = pd.read_csv(file, sep="\t", comment="#", header=None, names=["GTDB_taxonomy", sample], index_col=0)
    dfs.append(df)

dfs

merged = pd.concat(dfs, axis=1).fillna(0)

# Sort sample columns alphabetically
merged_sorted = merged.reindex(sorted(merged.columns), axis=1)

merged_sorted.to_csv("merged_metaphlan_GTDB.tsv", sep="\t")

print("Merge finished in python")

EOF

mv merged_metaphlan_GTDB.tsv metaphlan_out/

echo "Job done" 
