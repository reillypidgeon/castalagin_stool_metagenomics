#!/usr/bin/env bash

#SBATCH --job-name=PRJEB76307_setup
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
#SBATCH --time=00:05:00
#SBATCH --mem=16G

set -euo pipefail

# This portion of the script renames directories and files
# It extracts the useful sample name and ID, then renames the parent folder (containing read pairs) as well as the read pairs themselves

# Samples are in individual directories (e.g., ERR13245346 with long file names like NS.LH00147_0019.003.IDT_i7_196---IDT_i5_196.021_V1_R1.fastq.gz and NS.LH00147_0019.003.IDT_i7_196---IDT_i5_196.021_V1_R2.fastq.gz)
# Use a for loop to extract the sample name, then rename both the parent directory and the samples
for file in *.fastq.gz; do
	echo $file
	# Use grep to extract the subject_id and create a directory
	subject_id=$(echo $file | grep -Eo "0[0-9]{2}_V[1-4]")
	echo "${subject_id}"
	mkdir -p "${subject_id}"
	
	# Extract the short file name and rename the file
	new_file_name=$(echo $file | grep -Eo "0[0-9]{2}_V[1-4]_R[1-2]\.fastq\.gz")
	echo ${new_file_name}

	# Move the renamed file into the new directory
	mv $file "${subject_id}/${new_file_name}"	
done

echo "Finished renaming the samples and directories"
