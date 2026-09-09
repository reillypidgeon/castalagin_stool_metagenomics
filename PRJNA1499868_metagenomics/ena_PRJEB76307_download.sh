#!/usr/bin/env bash
# Log in to the Digital Research Alliance of Canada Narval Cluster
# From the login node (internet access needed)

# Define directories
project_dir="$SCRATCH/PRJNA1499868_MGX"
mkdir -p "${project_dir}"

# Create a directory for all raw reads data in the scratch directory
read_dir="${project_dir}/raw_reads"
mkdir -p "${read_dir}"
cd "${read_dir}"

# Download the raw sequencing data from PRJEB76307 from a list of urls
# Example url: ftp://ftp.sra.ebi.ac.uk/vol1/run/ERR132/ERR13245373/NS.LH00147_0019.004.IDT_i7_213---IDT_i5_213.061_V2_R1.fastq.gz
cat $SCRATCH/RP01-93_CC_CT/ena_PRJEB76307_urls.txt | parallel -j 8 wget -c -nc

# Start an interactive job before proceeding with the following steps

# This portion of the script renames directories and files
# It extracts the useful sample name and ID, then renames the parent folder (containing read pairs) as well as the read pairs themselves

# Samples are in individual directories (e.g., ERR13245346 with long file names like NS.LH00147_0019.003.IDT_i7_196---IDT_i5_196.021_V1_R1.fastq.gz and NS.LH00147_0019.003.IDT_i7_196---IDT_i5_196.021_V1_R2.fastq.gz)
# Use a for loop to extract the sample name, then rename both the parent directory and the samples
for dir in *; do
	echo $dir
	# Use grep to extract the R1 and R2 file names (e.g. 021_V1_R1)
	R1=$(ls $dir | grep -E -o "0[0-9]{2}_V[1-4]_R1[^ ]*gz$")
	R2=$(ls $dir | grep -E -o "0[0-9]{2}_V[1-4]_R2[^ ]*gz$")
	echo "R1 is $R1"
	echo "R2 is $R2"
	
	# Use grep again to extract the directory name (for renaming)
	DIR_NAME=$(echo $R1 | grep -E -o "0[0-9]{2}_V[1-4]")
	echo $DIR_NAME
	
	# Rename the samples
	mv ${dir}/*R1*.fastq.gz ${dir}/$R1
	mv ${dir}/*R2*.fastq.gz ${dir}/$R2
	
	# Rename the parent directory
	mv $dir $DIR_NAME
	ls $DIR_NAME
done
