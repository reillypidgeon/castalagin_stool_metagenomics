# Note on running the R code in this directory
The `gtdb_version_consolidation.R` script in this directory can be run in RStudio if desired. The directory containing the 3 metadata tables will need to be specified or the working directory can be changed using the `setwd` command. <br>
There are also full download (`01_gtdb_version_consolidation.sh`) and setup (`gtdb_version_consolidation.slurm`) scripts available for a DRAC cluster. <br>

In all cases, the following libraries are required: `dplyr` and `readr`. <br>
These can be installed using the following command: `install.packages(c('dplyr', 'readr'))` <br>
And called using `library(dplyr)` and `library(readr)` in the R session (already done in the R script).
