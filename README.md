# TCGA-BRCA Differential Expression & Survival Analysis

## Project Overview
*(To be completed once analysis is finished)*

---

## Progress Log

### Environment Setup (R + VS Code)
Set up R development environment in VS Code on Windows:
- Installed R 4.6.1 and manually added it to the system PATH (not done 
  automatically by the installer).
- Installed the VS Code R extension (REditorSupport).
- Installed the `languageserver` R package to enable VS Code's R support.

**Issues resolved:**
- Windows SmartScreen flagged the R installer as unrecognized;
resolved via "More info" → "Run anyway".
- CRAN package downloads (`languageserver`, `BiocManager`) repeatedly failed 
  or hung with `error reading from connection`, despite the network and 
  browser working fine. Cause: R's internal `libcurl`/`curl` download 
  methods were intermittently failing on this system.
Resolved by manually downloading the Windows binary `.zip` files from CRAN and installing 
locally with `install.packages(..., repos = NULL, type = "win.binary")`.

### Package Installation
Installed core Bioconductor/CRAN packages: `BiocManager`, `TCGAbiolinks`, 
`DESeq2`, `survival`, `survminer`.

**Issue resolved:** `BiocManager::install()` for large packages with many 
dependencies required patience (15-30 min) but completed successfully once 
the CRAN download issue above was fixed.

### Git / GitHub Setup
Initialized a Git repository via GitHub Desktop and published it as a 
public repo, to track project code and provide a portfolio-visible record 
of the work.

**Issue resolved:** Raw downloaded TCGA data files (UUID-named folders, 
hundreds of MB) were accidentally committed and pushed to GitHub before 
`.gitignore` was properly enforced. The causes were: (1) the data 
folder was tracked in the very first commit, before `.gitignore` existed, 
so ignoring it afterward didn't retroactively untrack it; and (2) an early 
`.gitignore` file was empty due to a failed terminal `echo` write. Fixed by 
rewriting `.gitignore` directly, verifying it with `git check-ignore`, then 
running `git rm -r --cached` to untrack the data files going forward.

### Data Acquisition (TCGA-BRCA)
Queried and downloaded RNA-seq gene expression data (STAR - Counts) for the 
full TCGA-BRCA cohort (1231 samples) via `TCGAbiolinks::GDCquery()` and 
`GDCdownload()`.

**Issues resolved:**
- TCGAbiolinks' default download method produced corrupted downloads 
  (`truncated gzip input`).
Fixed by installing the official **GDC Data Transfer Tool** (`gdc-client`) and switching `GDCdownload()` to `method = "client"`, which handled large transfers more reliably.
- Repeated `"GDC server down, try to use this package later"` errors, even 
  though the GDC API and portal were confirmed reachable and healthy via 
  direct `curl`/`httr` tests. The cause: TCGAbiolinks' internal status 
  check (`getGDCInfo()`) uses `jsonlite::fromJSON()`, which is incompatible 
  with the global R option `download.file.method = "curl"` set earlier to 
  fix the CRAN download issue (`"curl"` is valid for `download.file()` but 
  not for the `url()` connection `fromJSON()` relies on).
Fixed by changing the `.Rprofile` setting to `download.file.method = "libcurl"` and 
  `url.method = "libcurl"`, which is compatible with both use cases.

Successfully downloaded and assembled all 1231 samples via `GDCprepare()` 
into a `SummarizedExperiment` object, saved locally as `data/brca_data.rds` 
(excluded from Git via `.gitignore`).

### Immune Microenvironment Analysis (in progress)
Decided to extend the project beyond a standard tumor-vs-normal DE analysis 
by characterizing the tumor immune microenvironment, given how active this 
area is in current breast cancer research.

Ran `quanTIseq` immune cell deconvolution (via the `quantiseqr` Bioconductor 
package) on all 1231 TCGA-BRCA samples, estimating the relative proportion 
of 10 immune cell types per tumor from bulk RNA-seq expression.

**Issue resolved:** Initially attempted the broader `immunedeconv` wrapper 
package, but its Windows installation required several GitHub-only 
dependencies (`xCell`, `ComICS`) that failed to build, consistent with the 
package's own documentation recommending conda for exactly this reason. 
Switched to `quantiseqr`, a native Bioconductor package implementing the 
same quanTIseq method with reliable Windows binary support.

### PAM50 Subtype vs. Immune Infiltration
Merged quanTIseq immune deconvolution results with PAM50 molecular subtype 
annotations (already included in TCGAbiolinks' clinical metadata as 
`paper_BRCA_Subtype_PAM50`; no additional data source needed).

Ran Kruskal-Wallis tests (with Benjamini-Hochberg correction for multiple 
testing) across all 11 immune cell types. All 11 showed statistically 
significant differences in infiltration across the 5 PAM50 subtypes 
(adjusted p < 0.0005 for every cell type), with M2 macrophages 
(p_adj ≈ 1e-49) and CD4 T cells (p_adj ≈ 2e-24) showing the strongest 
associations — consistent with established literature on distinct immune 
microenvironments across breast cancer molecular subtypes.

Generated boxplots for all 11 immune cell types by subtype (`results/`), 
plus a summary statistics table (`results/kruskal_subtype_immune_tests.csv`).

**Next steps:** Link immune infiltration to survival outcomes; compare 
differential expression between immune-hot and immune-cold tumors.