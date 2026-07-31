#!/bin/bash

#SBATCH --job-name=featurecounts
#SBATCH --output=%x_%A_%a.out
#SBATCH --error=%x_%A_%a.err
#SBATCH --time=0:20:00
#SBATCH --array=0-65
#SBATCH --cpus-per-task=8
#SBATCH --mem=100G

date

# Load the required modules for featureCounts (subread) and downstream analysis
module load StdEnv/2023 subread/2.0.6 python/3.13.2
echo "Modules loaded"

# These are the directory variables for samples
OUT_DIR=$SCRATCH/RP01-93_CC_CT/RP01-93_CC_CT_analysis
BT2_DIR=$OUT_DIR/bt2_backmap_out

# Create output directory for featureCounts
FC_OUT=$OUT_DIR/fc_out
mkdir -p $FC_OUT

# Build array of directories - all directories have the same sample ID (e.g. 021_V1) as each read set
DIRS=(${BT2_DIR}/*/)
BAM_DIR=${DIRS[$SLURM_ARRAY_TASK_ID]}
SAMPLE_ID=$(basename "$BAM_DIR")
P_ID=$(basename ${BAM_DIR%_*}) # Extract the patient ID (before the underscore) from the sample ID

echo "Sample: $SAMPLE_ID"
echo "Patient: $P_ID"

# Define where featureCounts inputs are

BAM=$BAM_DIR"${SAMPLE_ID}_bt2_backmap_sorted.bam"
ANNOT=$OUT_DIR/prodigal_co_assembly_out/$P_ID

# Before running featureCounts, extract gene coordinate information from the prodigal genes fasta file
# The GFF does not work well with featureCounts, and we lose the gene numbering (e.g. k123_1, k123_2, etc.)

cd $ANNOT

# Create a SAF annotation file
awk '
BEGIN { OFS="\t" }
/^>/ {
    # Remove >
    gsub(/^>/, "", $1)

    gene_id = $1
    start   = $3
    end     = $5
    strand  = ($7 == "1") ? "+" : "-"

    # Extract contig name (everything except last _number)
    contig = gene_id
    sub(/_[0-9]+$/, "", contig)

    print gene_id, contig, start, end, strand
}
' ${P_ID}_prodigal_genes.fna > ${P_ID}_prodigal_annot.saf

head $ANNOT/"${P_ID}_prodigal_annot.saf"

# Define its location
SAF=$ANNOT/"${P_ID}_prodigal_annot.saf"

# Create a gene lengths file in the same location for downstream analyses
awk '
BEGIN { OFS="\t" }
/^>/ {
  if (len) print gene, len
  gene = substr($0,2)
  sub(/ .*/, "", gene)
  len = 0
  next
}
{ len += length($0) }
END { print gene, len }
' ${P_ID}_prodigal_genes.fna > ${P_ID}_prodigal_gene_lengths.tsv

# Run featureCounts in paired-end mode
# Require both reads to map and exclude chimeric pairs
echo "Running featureCounts"

mkdir -p $FC_OUT/${SAMPLE_ID}

featureCounts \
    -T $SLURM_CPUS_PER_TASK \
    -a ${SAF} \
    -F SAF \
    -p \
    -B \
    -C \
    -o ${FC_OUT}/${SAMPLE_ID}/${SAMPLE_ID}_featureCounts.txt \
    ${BAM}

echo "featureCounts completed!"
echo "Output written to: ${FC_OUT}/${SAMPLE_ID}"
head ${FC_OUT}/${SAMPLE_ID}/${SAMPLE_ID}_featureCounts.txt

# Now convert the featurecounts output to RPKM and TPM values
module load scipy-stack/2025a

# These are the directory variables for samples
FC_DIR=$OUT_DIR/fc_out # Redefine FC_OUT
LEN_DIR=$OUT_DIR/prodigal_co_assembly_out

# Create output directory for featureCounts conversion to RPKM and TPM (relative abundance)
FC_RA_OUT=$OUT_DIR/fc_ra_out
mkdir -p $FC_RA_OUT

cd $OUT_DIR

# Define where sample and patient-specific inputs are and create an output directory that is sample specific
FC_FILE=$FC_DIR/$SAMPLE_ID/"${SAMPLE_ID}_featureCounts.txt"
LEN_FILE=$LEN_DIR/$P_ID/"${P_ID}_prodigal_gene_lengths.tsv"
mkdir -p $FC_RA_OUT/$SAMPLE_ID
OUT_FILE=$FC_RA_OUT/$SAMPLE_ID/"${SAMPLE_ID}_fc_ra.tsv"

# Convert to real path to avoid confusion in Python
FC_FILE=$(realpath "${FC_FILE}")
LEN_FILE=$(realpath "${LEN_FILE}")
OUT_FILE=$(realpath "${OUT_FILE}")

# Check if gene lengths file is found first
if [[ ! -f "${LEN_FILE}" ]]; then
  echo "ERROR: Gene length file not found: ${LEN_FILE}"
  exit 1
fi

# Run the Python conversion script by taking input from the Unix environment
python featurecounts_to_RPKM_TPM.py $FC_FILE $LEN_FILE $OUT_FILE $P_ID $SAMPLE_ID

echo "Finished converting ${SAMPLE_ID} to RPKM and TPM"
