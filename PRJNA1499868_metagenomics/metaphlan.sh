#!/bin/bash

#SBATCH --time=6:00:00
#SBATCH --cpus-per-task=8
#SBATCH --mem=100G
#SBATCH --job-name=MO67_metaphlan
#SBATCH --output=%x.out
#SBATCH --error=%x.err

# Load the required modules
module load gcc blast samtools bedtools python/3.13.2 bowtie2 StdEnv/2023
echo "Modules loaded"

# Set variables for the directory containing raw reads and the sample_id
READ_DIR=$SCRATCH/RP01-94_MO67_MGX/fastp_bt2_qc/bt2_out/
SAMPLE_ID="MO67_A-D"

# Create new directory for metaphlan_4.1.1 output
mkdir -p $SCRATCH/RP01-94_MO67_MGX/metaphlan_out
OUT_DIR=$SCRATCH/RP01-94_MO67_MGX/metaphlan_out

# Set variable for the directory containing the metaphlan database
DB_DIR=$SCRATCH/metaphlan_databases

# Set variables for R1 and R2
R1=$READ_DIR/${SAMPLE_ID}_bt2_t2t_unaligned_R1.fastq.gz
R2=$READ_DIR/${SAMPLE_ID}_bt2_t2t_unaligned_R2.fastq.gz

# Generate your virtual environment in $SLURM_TMPDIR
virtualenv --no-download ${SLURM_TMPDIR}/env
source ${SLURM_TMPDIR}/env/bin/activate

# Install metaphlan_4.1.1 and its dependencies
pip install --no-index --upgrade pip
pip install --no-index metaphlan==4.1.1

# Run metaphlan
metaphlan $R1,$R2 \
--input_type fastq \
-o $OUT_DIR/${SAMPLE_ID}_metaphlan_out.txt \
--nproc $SLURM_CPUS_PER_TASK \
--index mpa_vJun23_CHOCOPhlAnSGB_202403 \
--bowtie2db $DB_DIR \
--bowtie2out $OUT_DIR/${SAMPLE_ID}_metaphlan_out.bowtie2.bz2

echo "Metaphlan pipeline finished"

# Convert SGB profiles to GTDB taxonomy (using metaphlan utility script)
sgb_to_gtdb_profile.py -d $DB_DIR/mpa_vJun23_CHOCOPhlAnSGB_202403.pkl \
-i $OUT_DIR/${SAMPLE_ID}_metaphlan_out.txt \
-o $OUT_DIR/${SAMPLE_ID}_metaphlan_out_GTDB.txt

echo "Converted SGB to GTDB taxonomy"
