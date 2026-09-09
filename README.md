# Code Repository for Giurleo et al. bioRxiv, 2026
Code used to analyze metagenomic samples derived from human fecal samples (Giurleo et al., Unpublished, 2026).<br>
The general workflows involve read QC, human read removal, contig assembly, protein prediction, and protein searching against databases.
<br>

>[!IMPORTANT]
> - Scripts used here work within the Digital Research Alliance of Canada (DRAC) Narval cluster <br>
> - Scripts were not optimized for portability across systems since most tools are already made available by DRAC

## Citation
DOI for BioRxiv or publication <br>

## Overview
### Tools and packages used in analyses
  1. Python (version )
  2. GNU Parallel (version )
  3. Fastp (version )
  4. FastQC (version )
  5. Bowtie2 (version )
  6. MetaPhlAn (version 4.. )
  7. MEGAHIT (version )
  8. Prodigal (version )
  9. FeatureCounts (version )
  10. Diamond (version )
  11. MMSeqs2 (version )
  12. SciPy-Stack (version 2026a)

### PRJEB76307_metagenomics
Scripts, metadata, and tables used in the analysis of metagenomics sequencing data from 
[Agrinier, A. L., et al. (2024). _Camu-camu decreases hepatic steatosis and liver injury markers in overweight, hypertriglyceridemic individuals: A randomized crossover trial_. Cell Rep Med 5(8): 101682.](https://doi.org/10.1016/j.xcrm.2024.101682) <br>

>ENA accession: [PRJEB76307](https://www.ebi.ac.uk/ena/browser/view/PRJEB76307) <br>
>Clinical trial accession: [NCT04130321](https://clinicaltrials.gov/study/NCT04130321) <br>

### PRJNA1499868_metagenomics
Scripts, metadata, and tables used in the analysis of metagenomics sequencing data from fecal sample MO67 (healthy donor) <br />

>NCBI accession: PRJNA1499868 <br>

### database_downloads <br>
This directory contains scripts for setting up the databases. <br> 
>[MetaPhlAn](https://cmprod1.cibio.unitn.it/biobakery4/metaphlan_databases/) <br>
>[UHGP](https://ftp.ebi.ac.uk/pub/databases/metagenomics/mgnify_genomes/human-gut/v2.0.2/protein_catalogue/)

## Usage
As mentioned above, the scripts in this code repository were not optimized for portability. <br>
To reuse the scripts as-is, clone this repository into your `scratch` directory:
```
# From the login node (home directory)
cd scratch
# Or from anywhere else
cd $SCRATCH
git clone https://github.com/reillypidgeon/castalagin_stool_metagenomics.git
```

## LICENSE
GNU GENERAL PUBLIC LICENSE (Version 3, 29 June 2007) <br>

Copyright (C) 2007 Free Software Foundation, Inc. <https://fsf.org/> <br>
Everyone is permitted to copy and distribute verbatim copies of this license document, but changing it is not allowed.
