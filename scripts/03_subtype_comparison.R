library(SummarizedExperiment)
library(ggplot2)

# Load data
brca_data <- readRDS("data/brca_data.rds")
quantiseq_results <- readRDS("data/quantiseq_results.rds")

# Build subtype lookup and merge with immune deconvolution results
sample_info <- data.frame(
  barcode = colData(brca_data)$barcode,
  subtype = colData(brca_data)$paper_BRCA_Subtype_PAM50
)
merged_data <- merge(quantiseq_results, sample_info, by.x = "Sample", by.y = "barcode")

# Keep only samples with a known PAM50 subtype
merged_data_tumor <- merged_data[!is.na(merged_data$subtype), ]

# Get all immune cell type columns (excludes Sample and subtype)
cell_types <- setdiff(colnames(merged_data_tumor), c("Sample", "subtype"))

# Run Kruskal-Wallis test for each immune cell type across subtypes
kruskal_results <- data.frame(
  cell_type = character(),
  chi_squared = numeric(),
  p_value = numeric(),
  stringsAsFactors = FALSE
)

for (cell in cell_types) {
  test <- kruskal.test(merged_data_tumor[[cell]] ~ merged_data_tumor$subtype)
  kruskal_results <- rbind(kruskal_results, data.frame(
    cell_type = cell,
    chi_squared = round(test$statistic, 2),
    p_value = test$p.value
  ))
}

# Adjust for multiple testing (Benjamini-Hochberg)
kruskal_results$p_adjusted <- p.adjust(kruskal_results$p_value, method = "BH")

# Sort by significance
kruskal_results <- kruskal_results[order(kruskal_results$p_value), ]

print(kruskal_results)

# Save the results table
write.csv(kruskal_results, "results/kruskal_subtype_immune_tests.csv", row.names = FALSE)

# Generate and save boxplots for every immune cell type
for (cell in cell_types) {
  p <- ggplot(merged_data_tumor, aes(x = subtype, y = .data[[cell]], fill = subtype)) +
    geom_boxplot() +
    theme_minimal() +
    labs(
      title = paste(cell, "Infiltration by PAM50 Subtype"),
      y = "Estimated Proportion",
      x = "PAM50 Subtype"
    ) +
    theme(legend.position = "none")
  
  ggsave(
    filename = paste0("results/", tolower(gsub("\\.", "_", cell)), "_by_subtype.png"),
    plot = p, width = 7, height = 5
  )
}