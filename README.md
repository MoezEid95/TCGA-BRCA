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

