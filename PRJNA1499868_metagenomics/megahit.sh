#!/bin/bash

#SBATCH --time=20:00:00
#SBATCH --cpus-per-task=12
#SBATCH --mem=120G
#SBATCH --job-name=MO67_megahit
#SBATCH --output=%x.out
#SBATCH --error=%x.err

date

# Load the required modules
module load megahit/1.2.9 StdEnv/2023
echo "Modules loaded"

# Set variable for the directory containing raw reads
READ_DIR=$SCRATCH/RP01-94_MO67_MGX/fastp_bt2_qc/bt2_out/
# Set variables for R1 and R2
R1=$READ_DIR/MO67_A-D_bt2_t2t_unaligned_R1.fastq.gz
R2=$READ_DIR/MO67_A-D_bt2_t2t_unaligned_R2.fastq.gz

# DO NOT create a new directory for megahit - it will create one in the --out-dir portion and cannot already exist

cd $SCRATCH/RP01-94_MO67_MGX/

# Run megahit on the MO67_A-D_bt2_unmapped reads
megahit -1 $R1 -2 $R2 \
--presets meta-sensitive \
--continue \
--min-contig-len 500 \
-t $SLURM_CPUS_PER_TASK \
--out-dir megahit_out

echo "Finished running megahit"
date
