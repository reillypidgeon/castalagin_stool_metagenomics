# Note on running the R code in this directory
The `gtdb_version_consolidation.R` script in this directory can be run in RStudio if desired. The directory containing the 3 metadata tables will need to be specified or the working directory can be changed using the `setwd` command. <br>
The metadata tables (`.tsv` after extracting) can be downloaded from the following links (note that some files are `.tar.gz` and one is `.tsv.gz`):
```
base_url="https://data.gtdb.ecogenomic.org/releases"
gtdb_r202="${base_url}/release202/202.0/bac120_metadata_r202.tar.gz"
gtdb_r207="${base_url}/release207/207.0/bac120_metadata_r207.tar.gz"
gtdb_r232="${base_url}/release232/232.0/bac120_metadata_r232.tsv.gz"
```

Full download (`01_gtdb_version_consolidation.sh`) and setup (`gtdb_version_consolidation.slurm`) scripts are also available for a DRAC cluster. <br>

In all cases, the following libraries are required: `dplyr` and `readr`. <br>
If these packages have [not yet been installed](../README.md (#Usage)), run the following in an interactive R session: `install.packages(c('dplyr', 'readr'))`.
Libraries can then be loaded using `library(dplyr)` and `library(readr)` in the R session (already done in the R script).
