#!/usr/bin/env Rscript

# Ensure that "remotes" and "biobakery/maaslin3" are already installed via BiocManager

# Load libraries
library(maaslin3)
library(dplyr)
library(tibble)
library(stringr)
library(vegan)
library(ggplot2)

# Running this script from a project directory that contains tool output directories 

#===================== Table Import and Setup =====================

# Take positional input
args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 2) {
  stop("Error: Invalid number of arguments.\nUsage: Rscript alpha_beta_maaslin3.R <merged_metaphlan_file> <metadata_file>", call. = FALSE)
}

# Import the full GTDB converted metaphlan table for the study (metaphlan output)
metaphlan_file <- args[1]
metaphlan_table <- read.csv(metaphlan_file, row.names = 1, sep = '\t', check.names = FALSE)

# Import the metadata associated with the study
metadata_file <- args[2]
metadata_table <- read.csv(metadata_file, row.names = 1, sep = '\t', check.names = FALSE)

# Add a sample_id column based on the row name (which was originally sample_id)
metadata_table$sample_id <- rownames(metadata_table)

# Also add a "P" to each subject_id number to keep as a categorical variable
metadata_table$subject_id <- paste0("P", metadata_table$subject_id)

# Only keep the rows with species flags in the metaphlan table (s__)
taxa <- rownames(metaphlan_table)
taxa_species <- grepl("s__", taxa)
metaphlan_table_species <- metaphlan_table[taxa_species, ]
taxa_rename <- rownames(metaphlan_table_species)
taxa_rename <- sub(".*f__", "", taxa_rename) # If we cut after the family level in the name, we get an error from species without genus or species names
rownames(metaphlan_table_species) <- taxa_rename

# Transpose the metaphlan_table_species
metaphlan_table_species_t <- as.data.frame(t(metaphlan_table_species))

print("All tables have been appropriately set up for downstream analyses")

#===================== Vegan - Alpha Diversity =====================

# Calculate the alpha diversity and add to the metadata table
metadata_table$shannon <- diversity(metaphlan_table_species_t, index = "shannon")
metadata_table$simpson <- diversity(metaphlan_table_species_t, index = "simpson")
metadata_table$richness <- specnumber(metaphlan_table_species_t)
print(metadata_table)

# Plot the alpha diversity
ggplot(metadata_table, aes(treatment, shannon, group = subject_id)) + geom_point(size = 4) + geom_line(alpha = 0.4) + theme_classic() + theme(aspect.ratio = 1) + scale_x_discrete(limits = rev) +  scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.05)))
ggsave("shannon_alpha_diversity.pdf")
ggplot(metadata_table, aes(treatment, simpson, group = subject_id)) + geom_point(size = 4) + geom_line(alpha = 0.4) + theme_classic() + theme(aspect.ratio = 1) + scale_x_discrete(limits = rev) + scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.05)))
ggsave("simpson_alpha_diversity.pdf")
ggplot(metadata_table, aes(treatment, richness, group = subject_id)) + geom_point(size = 4) + geom_line(alpha = 0.4) + theme_classic() + theme(aspect.ratio = 1) + scale_x_discrete(limits = rev) +  scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.05)))
ggsave("richness_alpha_diversity.pdf")

# Statistics on alpha diversity metrics (Wilcoxon nonparametric test)
with(metadata_table, wilcox.test(shannon[treatment == "pre"], shannon[treatment == "post"], paired = TRUE))
with(metadata_table, wilcox.test(simpson[treatment == "pre"], simpson[treatment == "post"], paired = TRUE))
with(metadata_table, wilcox.test(richness[treatment == "pre"], richness[treatment == "post"], paired = TRUE)) # Note that there are ties here which don't allow for proper p value calculation

#===================== Vegan - Beta Diversity =====================

# Calculate distances using different methods
bray <- vegdist(metaphlan_table_species_t, method = "bray")
jaccard <- vegdist(metaphlan_table_species_t, method = "jaccard")
r_aitchison <- vegdist(metaphlan_table_species_t, method = "robust.aitchison")

# Perform PCoA, outputting eigenvalues for 2 axes (2-D plot)
pcoa_bray <- cmdscale(bray, eig = TRUE, k = 2)
pcoa_jaccard <- cmdscale(jaccard, eig = TRUE, k = 2)
pcoa_r_aitchison <- cmdscale(r_aitchison, eig = TRUE, k = 2)

# Do ordination
ordination_bray <- data.frame(sample_id = rownames(metadata_table),
                              PCoA1 = pcoa_bray$points[,1], 
                              PCoA2 = pcoa_bray$points[,2])
ordination_jaccard <- data.frame(sample_id = rownames(metadata_table),
                              PCoA1 = pcoa_jaccard$points[,1], 
                              PCoA2 = pcoa_jaccard$points[,2])
ordination_r_aitchison <- data.frame(sample_id = rownames(metadata_table),
                              PCoA1 = pcoa_r_aitchison$points[,1], 
                              PCoA2 = pcoa_r_aitchison$points[,2])

# Merge ordination with metadata
ordination_bray_merge <- left_join(metadata_table, ordination_bray, by = "sample_id")
ordination_jaccard_merge <- left_join(metadata_table, ordination_jaccard, by = "sample_id")
ordination_r_aitchison_merge <- left_join(metadata_table, ordination_r_aitchison, by = "sample_id")

# Calculate the variance explained for each PCoA axis (1 and 2)
var_bray <- round(pcoa_bray$eig / sum(pcoa_bray$eig[pcoa_bray$eig > 0]) * 100, 1)
var_jaccard <- round(pcoa_jaccard$eig / sum(pcoa_jaccard$eig[pcoa_jaccard$eig > 0]) * 100, 1)
var_r_aitchison <- round(pcoa_r_aitchison$eig / sum(pcoa_r_aitchison$eig[pcoa_r_aitchison$eig > 0]) * 100, 1)

# Perform PERMANOVA
perm <- how(blocks = metadata_table$subject_id, nperm = 999)

permanova_bray <- adonis2(bray ~ treatment, data = metadata_table, permutations = perm)
permanova_jaccard <- adonis2(jaccard ~ treatment, data = metadata_table, permutations = perm)
permanova_r_aitchison <- adonis2(r_aitchison ~ treatment, data = metadata_table, permutations = perm)

# Plot beta diversity with ggplot2
ggplot(ordination_bray_merge, aes(x = PCoA1, y = PCoA2, color = treatment, group = subject_id)) + 
  geom_point(size = 4) + geom_path(alpha = 2) + theme_bw() + scale_color_brewer(palette = "Set1") + theme(aspect.ratio = 1) +
  labs(x = paste0("PCoA1 (", var_bray[1], "%)"), y = paste0("PCoA2 (", var_bray[2], "%)"), title = paste0("Bray-Curtis: R^2 = ",permanova_bray$R2[1],", p = ",permanova_bray$`Pr(>F)`[1],""))
ggsave("bray_beta_diversity.pdf")

ggplot(ordination_jaccard_merge, aes(x = PCoA1, y = PCoA2, color = treatment, group = subject_id)) +
  geom_point(size = 4) + geom_path(alpha = 2) + theme_bw() + scale_color_brewer(palette = "Set1") + theme(aspect.ratio = 1) +
  labs(x = paste0("PCoA1 (", var_jaccard[1], "%)"), y = paste0("PCoA2 (", var_jaccard[2], "%)"), title = paste0("Jaccard: R^2 = ",permanova_jaccard$R2[1],", p = ",permanova_jaccard$`Pr(>F)`[1],""))
ggsave("jaccard_beta_diversity.pdf")

ggplot(ordination_r_aitchison_merge, aes(x = PCoA1, y = PCoA2, color = treatment, group = subject_id)) +
  geom_point(size = 4) + geom_path(alpha = 2) + theme_bw() + scale_color_brewer(palette = "Set1") + theme(aspect.ratio = 1) +
  labs(x = paste0("PCoA1 (", var_r_aitchison[1], "%)"), y = paste0("PCoA2 (", var_r_aitchison[2], "%)"), title = paste0("Robust Aitchison: R^2 = ",permanova_r_aitchison$R2[1],", p = ",permanova_r_aitchison$`Pr(>F)`[1],""))
ggsave("r_aitchinson_beta_diversity.pdf")

#====================== MaasLin3 - Linear Models =====================

# Factor the metadata table (treatment)
# Positive coefficient in results is increased after treatment
# Negative coefficient in results is decreased after treatment
metadata_table_maaslin <- metadata_table
metadata_table_maaslin$treatment <- as.factor(metadata_table_maaslin$treatment)
metadata_table_maaslin$treatment <- relevel(metadata_table_maaslin$treatment, ref = "pre")
metadata_table_maaslin$subject_id <- as.factor(metadata_table_maaslin$subject_id)
metadata_table_maaslin$reads <- as.numeric(metadata_table_maaslin$reads)

# Run maaslin3
fit <- maaslin3(
  input_data = metaphlan_table_species_t,
  input_metadata = metadata_table_maaslin,
  output = "maaslin3_out",
  normalization = "TSS",
  transform = "LOG",
  augment = TRUE,
  standardize = TRUE,
  formula = "~ treatment + reads + (1|subject_id)",
  max_pngs = 30
)
