# Make sure R version >= 4.4
# Current version 4.4.2

# Ensure that "remotes" and "biobakery/maaslin3" are already installed via BiocManager
# Load libraries
library(maaslin3)
library(dplyr)
library(tibble)
library(stringr)
library(vegan)
library(ggplot2)

setwd("C:/Users/Reilly/OneDrive - McGill University/PhD/Data/RP01-93 CC Clinical Trial Fecal Extraction of Metabolites 20240509/RP01-93 20260508 Marette CC Metaphlan Megahit/maaslin3")

#===================== Table Import and Setup ============================================================================


# Import the full GTDB converted table for the study (metaphlan4 output)
metaphlan_path <- "C:/Users/Reilly/OneDrive - McGill University/PhD/Data/RP01-93 CC Clinical Trial Fecal Extraction of Metabolites 20240509/RP01-93 20260508 Marette CC Metaphlan Megahit/metaphlan_out/merged_metaphlan_GTDB.tsv"
metaphlan_table <- read.csv(metaphlan_path, row.names = 1, sep = '\t', check.names = FALSE)

# Import the metadata associated with the study
metadata_path <- "C:/Users/Reilly/OneDrive - McGill University/PhD/Data/RP01-93 CC Clinical Trial Fecal Extraction of Metabolites 20240509/RP01-93 20260508 Marette CC Metaphlan Megahit/maaslin3/sample_metadata.tsv"
metadata_table <- read.csv(metadata_path, row.names = 1, sep = '\t', check.names = FALSE)

# Add a sample_id column based on the rowname
metadata_table$sample_id <- rownames(metadata_table)

# Also add a "P" to each patient number to keep as a categorical variable
metadata_table$patient <- paste0("P", metadata_table$patient)

# Only keep the rows with species flags (s__)
taxa <- rownames(metaphlan_table)
taxa_species <- grepl("s__", taxa)
print(taxa)
print(taxa_species)

# Remove rows without a match to "s__"
metaphlan_table_species <- metaphlan_table[taxa_species, ]
taxa_rename <- rownames(metaphlan_table_species)
print(taxa_rename)
taxa_rename <- sub(".*f__", "", taxa_rename) # If we cut after the family level in the name, we get an error from species without genus or species names
print(taxa_rename)
rownames(metaphlan_table_species) <- taxa_rename


# Transpose the metaphlan_table_species
metaphlan_table_species_t <- as.data.frame(t(metaphlan_table_species))

# Now, all tables have been appropriately set up for downstream analyses...

#===================== Vegan - Alpha Diversity ============================================================================

# Calculate the alpha diversity and add to the metadata table
metadata_table$shannon <- diversity(metaphlan_table_species_t, index = "shannon")
metadata_table$simpson <- diversity(metaphlan_table_species_t, index = "simpson")
metadata_table$richness <- specnumber(metaphlan_table_species_t)

# Plot the alpha diversity
ggplot(metadata_table, aes(treatment, shannon, group = patient)) + geom_point(size = 4) + geom_line(alpha = 0.4) + theme_classic() + theme(aspect.ratio = 1) + scale_x_discrete(limits = rev) +  scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.05)))
ggplot(metadata_table, aes(treatment, simpson, group = patient)) + geom_point(size = 4) + geom_line(alpha = 0.4) + theme_classic() + theme(aspect.ratio = 1) + scale_x_discrete(limits = rev) + scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.05)))
ggplot(metadata_table, aes(treatment, richness, group = patient)) + geom_point(size = 4) + geom_line(alpha = 0.4) + theme_classic() + theme(aspect.ratio = 1) + scale_x_discrete(limits = rev) +  scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.05)))

# Statistics on alpha diversity metrics (Wilcoxon nonparametric test)
with(metadata_table, wilcox.test(shannon[treatment == "pre"], shannon[treatment == "post"], paired = TRUE))
with(metadata_table, wilcox.test(simpson[treatment == "pre"], simpson[treatment == "post"], paired = TRUE))
with(metadata_table, wilcox.test(richness[treatment == "pre"], richness[treatment == "post"], paired = TRUE)) # Note that there are ties here which don't allow for proper p value calc

#===================== Vegan - Beta Diversity ============================================================================

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
perm <- how(blocks = metadata_table$patient, nperm = 999)

permanova_bray <- adonis2(bray ~ treatment, data = metadata_table, permutations = perm)
permanova_jaccard <- adonis2(jaccard ~ treatment, data = metadata_table, permutations = perm)
permanova_r_aitchison <- adonis2(r_aitchison ~ treatment, data = metadata_table, permutations = perm)

# Plot beta diversity with ggplot2
ggplot(ordination_bray_merge, aes(x = PCoA1, y = PCoA2, color = treatment, group = patient)) + 
  geom_point(size = 4) + geom_path(alpha = 2) + theme_bw() + scale_color_brewer(palette = "Set1") + theme(aspect.ratio = 1) +
  labs(x = paste0("PCoA1 (", var_bray[1], "%)"), y = paste0("PCoA2 (", var_bray[2], "%)"), title = paste0("Bray-Curtis: R^2 = ",permanova_bray$R2[1],", p = ",permanova_bray$`Pr(>F)`[1],""))

ggplot(ordination_jaccard_merge, aes(x = PCoA1, y = PCoA2, color = treatment, group = patient)) +
  geom_point(size = 4) + geom_path(alpha = 2) + theme_bw() + scale_color_brewer(palette = "Set1") + theme(aspect.ratio = 1) +
  labs(x = paste0("PCoA1 (", var_jaccard[1], "%)"), y = paste0("PCoA2 (", var_jaccard[2], "%)"), title = paste0("Jaccard: R^2 = ",permanova_jaccard$R2[1],", p = ",permanova_jaccard$`Pr(>F)`[1],""))

ggplot(ordination_r_aitchison_merge, aes(x = PCoA1, y = PCoA2, color = treatment, group = patient)) +
  geom_point(size = 4) + geom_path(alpha = 2) + theme_bw() + scale_color_brewer(palette = "Set1") + theme(aspect.ratio = 1) +
  labs(x = paste0("PCoA1 (", var_r_aitchison[1], "%)"), y = paste0("PCoA2 (", var_r_aitchison[2], "%)"), title = paste0("Robust Aitchison: R^2 = ",permanova_r_aitchison$R2[1],", p = ",permanova_r_aitchison$`Pr(>F)`[1],""))


#====================== MaasLin3 - Linear Models ========================================================================

# Factor the metadata table (treatment)
# Positive coefficient in results is increased after treatment
# Negative coefficient in results is decreased after treatment
metadata_table_maaslin <- metadata_table
metadata_table_maaslin$treatment <- as.factor(metadata_table_maaslin$treatment)
metadata_table_maaslin$treatment <- relevel(metadata_table_maaslin$treatment, ref = "pre")
metadata_table_maaslin$patient <- as.factor(metadata_table_maaslin$patient)
metadata_table_maaslin$reads <- as.numeric(metadata_table_maaslin$reads)

patient_codes <- metadata_table$patient

setwd("C:/Users/Reilly/Desktop")

# Run maaslin3
fit <- maaslin3(
  input_data = metaphlan_table_species_t,
  input_metadata = metadata_table_maaslin,
  output = "maaslin3_species_out_20260729",
  normalization = "TSS",
  transform = "LOG",
  augment = TRUE,
  standardize = TRUE,
  formula = "~ treatment + reads + (1|patient)",
  min_prevalence = 0.1,
  min_abundance = 1e-4,
  max_pngs = 30
)
