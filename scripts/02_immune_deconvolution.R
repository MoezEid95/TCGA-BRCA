library(TCGAbiolinks)
library(SummarizedExperiment)
library(quantiseqr)

# Load previously saved expression data
brca_data <- readRDS("data/brca_data.rds")

# Extract TPM-normalized expression matrix
expr_tpm <- assay(brca_data, "tpm_unstrand")

# Map Ensembl IDs to gene symbols, collapsing duplicates by summing
gene_symbols <- rowData(brca_data)$gene_name
expr_tpm_collapsed <- rowsum(expr_tpm, group = gene_symbols)

# Run quanTIseq immune deconvolution
quantiseq_results <- quantiseqr::run_quantiseq(
  expression_data = expr_tpm_collapsed,
  is_arraydata = FALSE,
  is_tumordata = TRUE,
  scale_mRNA = TRUE
)

# Save results
saveRDS(quantiseq_results, file = "data/quantiseq_results.rds")