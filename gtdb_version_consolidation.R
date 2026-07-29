library(dplyr)
library(readr)

# Go to the directory that contains all the metadata files for different GTDB release versions
# These metadata tables were downloaded from: https://data.gtdb.ecogenomic.org/releases/

setwd("C:/Users/Reilly/Desktop")

# Load the metadata tables for each GTDB release version

df_r202 <- read.csv("bac120_metadata_r202.tsv", sep = '\t') # Released 2021-04-26
df_r207 <- read.csv("bac120_metadata_r207.tsv", sep = '\t') # Released 2022-04-01
df_r232 <- read.csv("bac120_metadata_r232.tsv", sep = '\t') # Released 2026-04-04

# Subset the dataframes, keeping the accession and gtdb_taxonomy columns, then rename the taxonomy by adding the release version
df_r202_subset <- df_r202[,c("accession", "gtdb_taxonomy")]
df_r202_subset <- df_r202_subset %>% rename(gtdb_taxonomy_r202 = gtdb_taxonomy)

df_r207_subset <- df_r207[,c("accession", "gtdb_taxonomy")]
df_r207_subset <- df_r207_subset %>% rename(gtdb_taxonomy_r207 = gtdb_taxonomy)

df_r232_subset <- df_r232[,c("accession", "ncbi_assembly_name", "ncbi_strain_identifiers", "ncbi_taxonomy", "gtdb_taxonomy")]
df_r232_subset <- df_r232_subset %>% rename(gtdb_taxonomy_r232 = gtdb_taxonomy)
df_r232_subset <- df_r232_subset %>% rename(ncbi_taxonomy_r232 = ncbi_taxonomy)

# Merge the dataframes and export a tab-separated file
merged_r232_r207_r202 <- df_r232_subset %>%
  left_join(df_r207_subset, by = "accession") %>%
  left_join(df_r202_subset, by = "accession")

write_tsv(merged_r232_r207_r202, file = "bac120_merged_r232_r207_r202.tsv")
