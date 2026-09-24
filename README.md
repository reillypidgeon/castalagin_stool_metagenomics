# Code Repository for Giurleo et al. bioRxiv, 2026
Repository for code used in the Castagner Lab (McGill University) for the analysis of metagenomic samples derived from human fecal samples.<br>
<br>
The general workflows involve read QC, human read removal, relative abundance determination, contig assembly, protein prediction, and protein searching against databases.
<br>

>[!IMPORTANT]
> - Scripts used here work within the Digital Research Alliance of Canada (DRAC) Narval cluster <br>
> - Scripts were not optimized for portability across systems since most tools are already made available by DRAC
> - Some paths are hardcoded starting from the `$SCRATCH` directory (`/home/username/scratch`) to minimize the need for user input

## Citation
BioRxiv TBD <br>

## Directory Overview
### PRJEB76307_metagenomics
Scripts, metadata, and tables used in the analysis of metagenomic sequencing data from 
[Agrinier, A. L., et al. (2024). _Camu-camu decreases hepatic steatosis and liver injury markers in overweight, hypertriglyceridemic individuals: A randomized crossover trial_. Cell Rep Med 5(8): 101682.](https://doi.org/10.1016/j.xcrm.2024.101682)
>ENA accession: [PRJEB76307](https://www.ebi.ac.uk/ena/browser/view/PRJEB76307) <br>
>Clinical trial accession: [NCT04130321](https://clinicaltrials.gov/study/NCT04130321) <br>

- `01_ena_PRJEB76307_download.sh`: Shell script to download metagenomic sequencing reads from the NCT04130321 clinical trial
    - Note that there is an alternative interactive tutorial that uses the Globus CLI (`ena_PRJEB76307_globus_download.md`), which is much faster, but requires some additional setup
    - If the `01_ena_PRJEB76307_download.sh` fails (some file transfers can fail), try downloading from Globus using the `ena_PRJEB76307_globus_download.md` tutorial
- `02_fastp_bt2_qc_array.slurm`: Shell (slurm) script to trim reads and remove host reads
- `03_metaphlan_array.slurm`: Shell (slurm) script to determine relative abundance of taxa
- `04_metaphlan_merge.slurm`: Shell (slurm) script to merge MetaPhlAn relative abundance tables (for all samples) and perform alpha diversity, beta diversity, and [MaAsLin3](https://github.com/biobakery/maaslin3) (Microbiome Multivariable Associations with Linear Models) analyses
- `05_megahit_prodigal_co_array.slurm`: Shell (slurm) script to co-assemble reads (by subject) into contigs and predict proteins
- `06_diamond_co_array.slurm`: Shell (slurm) script to search user-defined queries (`queries.faa`) against predicted proteins
- `07_diamond_co_merge.slurm`: Shell (slurm) script to merge diamond search tables (for all samples) and produce a best-hits FASTA file
- `08_diamond_co_uhgp.slurm`: Shell (slurm) script to search the best-hits FASTA file against the UHGP database
- `09_bt2_backmap_array.slurm`: Shell (slurm) script to map quality-controlled reads onto contigs from co-assemblies (for all samples)
- `10_featurecounts_array.slurm`: Shell (slurm) script to count reads mapping to protein-coding sequences, then to determine the relative abundance as reads per kb per million mapped reads (RPKM) and transcripts per million (TPM)
- `11_RPKM_TMP_merge.slurm`: Shell (slurm) script to merge RPKM and TPM relative abundance tables (for all samples)
- Multiple Python and SLURM scripts (`.py` and `.slurm`)
- `alpha_beta_maaslin3.R`: R script used to analyze MetaPhlAn output
- `ena_PRJEB76307_urls.txt`: List of URLs for the download script
- `ena_PRJEB76307_globus_download.md`: Tutorial to download metagenomic sequencing reads from the NCT04130321 clinical trial using the Globus CLI tool.
- `sample_metadata.tsv`: Sample metadata for the `alpha_beta_maaslin3.R` script
- `queries.faa`: Query FASTA file for diamond search
- `string_pattern_mapping.tsv`: Table of additional metadata to add to tables based on partial string matching

### PRJNA1499868_metagenomics
Scripts, metadata, and tables used to analyze metagenomic sequencing data from fecal sample MO67 in this study. <br>
>NCBI BioProject: PRJNA1499868 <br>
>NCBI SRA Accession: SRR39796052

- `01_ncbi_PRJNA1499868_download.sh`: Shell script to download metagenomic sequencing reads from sample MO67
- `02_fastp_bt2_qc.slurm`: Shell (slurm) script to trim reads and remove host reads
- `03_metaphlan.slurm`: Shell (slurm) script to determine relative abundance of taxa
- `04_megahit_prodigal.slurm`: Shell (slurm) script to assemble reads into contigs and predict proteins
- `05_diamond_uhgp.slurm`: Shell (slurm) script to search user-defined queries (`queries.faa`) against predicted proteins, then to search the best-hits FASTA file against the UHGP database
-  Multiple Python and SLURM scripts (`.py` and `.slurm`)
-  `queries.faa`: Query FASTA file for diamond search
-  `string_pattern_mapping.tsv`: Table of additional metadata to add to tables based on partial string matching

### database_downloads <br>
Scripts for downloading and setting up the various databases used in the metagenomic analyses. <br>
These scripts require internet access for the download portion, then schedule jobs via the `sbatch` command for the setup portion.
- `01_metaphlan_db_download.sh`: Shell script to download and set up the MetaPhlAn database (version mpa_vJun23_CHOCOPhlAnSGB_202403), which uses [GTDB release 207](https://github.com/biobakery/MetaPhlAn/blob/master/metaphlan/utils/mpa_vJun23_CHOCOPhlAnSGB_202403_SGB2GTDB_r207.tsv), for relative abundance determination
- `02_uhgp_download.sh`: Shell script to download and set up the Unified Human Gastrointestinal Proteome diamond database (version 2.0.2), which uses [GTDB release 202](https://ftp.ebi.ac.uk/pub/databases/metagenomics/mgnify_genomes/human-gut/v2.0.2/README_v2.0.2.txt), for predicted protein matching
- `03_t2t_hg39_setup.sh`: Shell script to download and set up the Telomere-to-Telomere (t2t) human genome (version GCF_009914755.1_T2T-CHM13v2.0) bowtie2 database for human read removal
- Multiple SLURM scripts (`.slurm`)

### gtdb_versions
- '01_gtdb_version_consolidation.sh: Shell script to download GTDB metadata tables for releases 202, 207, 232
- `gtdb_version_consolidation.R`: R script to build a table of GTDB version (releases 202, 207, 232) equivalence based on releases relevant to the analyses in this manuscript.
- `gtdb_version_consolidation.slurm`: Shell (slurm) script to call the `gtdb_version_consolidation.R` script

## Usage
As mentioned above, the scripts in this code repository were not optimized for portability. <br>
To reuse the scripts as-is (in a DRAC cluster), clone this repository into your `scratch` directory:
```
# From the login node's home directory
cd scratch
# Or from anywhere else
cd $SCRATCH

git clone https://github.com/reillypidgeon/castalagin_stool_metagenomics.git
```
R scripts in some of the analyses require multiple libraries to work properly. These need to be installed beforehand, which can be done in an interactive R session (in your DRAC cluster) with the following code:
```
if (!require("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
BiocManager::install("remotes")
BiocManager::install("biobakery/maaslin3")
install.packages(c("dplyr", "readr", "tibble", "stringr", "vegan", "ggplot2"))
# For the CRAN mirrors, select #1
```
You can then run scripts from the individual directories in the cloned repository. These scripts are set up to work without any positional input. As long as the repository is cloned into your `$SCRATCH` directory, the scripts should work.
```
# For a database download
cd castalagin_stool_metagenomics/database_downloads
bash 01_metaphlan_db_download.sh

# Or for any of the analyses in the metagenomics scripts directories
cd castalagin_stool_metagenomics/PRJNA1499868_metagenomics
sbatch 02_fastp_bt2_qc.slurm
```
>[!IMPORTANT]
> Scripts are meant to be run using either the `bash` or `sbatch` commands from the cluster's login node
> - Numbered scripts that end with `.sh` should be run using the `bash` command since they require internet access for downloads
> - Numbered scripts that end with `.slurm` should be run using the `sbatch` command
> - Other scripts are called by the numbered scripts

### Tools and packages used in analyses
  1. python (version 3.13.2)
  2. r (version 4.6.1)
  3. StdEnv (version 2023)
  4. gcc (version 12.3)
  5. [GNU Parallel](https://doi.org/10.5281/zenodo.7958356)
  6. [scipy-stack](https://pypi.org/project/scipy-stack/) (version 2026a)
  7. [fastp](https://github.com/opengene/fastp) (version 1.0.1 )
  8. [fastqc](https://github.com/s-andrews/fastqc) (version 0.12.1)
  9. [bowtie2](https://github.com/benlangmead/bowtie2) (version 2.5.4)
  10. [metaphlan](https://github.com/biobakery/metaphlan) (version 4.1.1)
  11. blast (version 2.2.26)
  12. [samtools](https://github.com/samtools/samtools) (version 1.22.1)
  13. [bedtools](https://github.com/arq5x/bedtools2) (version 2.31.0)
  14. [megahit](https://github.com/voutcn/MEGAHIT) (version 1.2.9)
  15. [prodigal](https://github.com/hyattpd/prodigal) (version 2.6.3)
  16. [subread](https://github.com/ShiLab-Bioinformatics/subread) (version 2.0.6)
  17. [diamond](https://github.com/bbuchfink/diamond) (version 2.1.11)
  18. [dplyr](https://github.com/tidyverse/dplyr) (version 1.2.1)
  19. [readr](https://github.com/tidyverse/readr) (version 2.2.0)
  20. [maaslin3](https://github.com/biobakery/maaslin3) (version 1.5.6)
  21. [tibble](https://github.com/tidyverse/tibble) (version 3.3.1)
  22. [stringr](https://github.com/tidyverse/stringr) (version 1.6.0)
  23. [vegan](https://github.com/vegandevs/vegan) (version 2.7.6)
  24. [ggplot2](https://github.com/tidyverse/ggplot2) (version 4.0.3)

## LICENSE
GNU GENERAL PUBLIC LICENSE (Version 3, 29 June 2007) <br>

Copyright (C) 2007 Free Software Foundation, Inc. <https://fsf.org/> <br>
Everyone is permitted to copy and distribute verbatim copies of this license document, but changing it is not allowed.
