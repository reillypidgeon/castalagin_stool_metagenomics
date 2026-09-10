#!/usr/bin/env bash

#SBATCH --job-name=PRJEB76307_setup
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
#SBATCH --time=00:15:00
#SBATCH --mem=16G

set -euo pipefail

# This portion of the script renames directories and files
# It extracts the useful sample name and ID, then renames the parent folder (containing read pairs) as well as the read pairs themselves

# Samples are in individual directories (e.g., ERR13245346 with long file names like NS.LH00147_0019.003.IDT_i7_196---IDT_i5_196.021_V1_R1.fastq.gz and NS.LH00147_0019.003.IDT_i7_196---IDT_i5_196.021_V1_R2.fastq.gz)
# Use a for loop to extract the sample name, then rename both the parent directory and the samples
for dir in *; do
	echo "$dir"
	# Use grep to extract the R1 and R2 file names (e.g. 021_V1_R1)
	R1=$(ls $dir | grep -E -o "0[0-9]{2}_V[1-4]_R1[^ ]*gz$")
	R2=$(ls $dir | grep -E -o "0[0-9]{2}_V[1-4]_R2[^ ]*gz$")
	echo "R1 is $R1"
	echo "R2 is $R2"
	
	# Use grep again to extract the directory name (for renaming)
	dir_name=$(echo "$R1" | grep -E -o "0[0-9]{2}_V[1-4]")
	echo $dir_name
	
	# Rename the samples
	mv ${dir}/*R1*.fastq.gz ${dir}/$R1
	mv ${dir}/*R2*.fastq.gz ${dir}/$R2
	
	# Rename the parent directory
	mv $dir $dir_name
done

echo "Finished renaming the samples and directories"
