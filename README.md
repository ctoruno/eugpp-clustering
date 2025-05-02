## Project Overview

This repository contains the source code for performing a sequence of preprocessing, dimensionality-reduction, and clustering routines using both K-Means and Gaussian Mixture Models to the EU GPP data from the Eurovoices project. The pipeline is divided into three main stages:

### 1. Multiple Imputation (R / MICE)

- Script: `lib/R/src/MICE.R`
- Entrypoint: `lib/R/main.R`
- Purpose: Handle missing survey responses via chained equations; outputs five imputed datasets per dimension per survey group.

Access to the EU-S Data SharePoint Folder is required for running the MICE imputations.

### 2. Non-Linear PCA (R / NLPCA)

- Script: `lib/R/src/NLPCA.R`
- Entrypoint: `lib/R/main.R` (it requires the imputations produced through MICE)
- Purpose: Reduce a large set of ordinal survey items into a lower-dimensional factor representation.

### 3. Clustering (Python / KMeans & GMM)

#### 3.1 UMAP reduction

- Script: `lib/python/src/umap.py`
- Entrypoint: `lib/python/main.py`
- Purpose: Reduces the features produced by the NLPCA to a 2-dimensional plane for visualization purposes

#### 3.2 Exploratory Data Analysis (EDA)

- Script: `lib/python/src/clustering.py`
- Entrypoint: `lib/python/main.py`
- Purpose: Additional analysis that supports the decisions taken in the KMeans and GMM clustering

#### 3.3 Clustering Routines

- Script: `lib/python/src/clustering.py`
- Entrypoint: `lib/python/main.py`
- Purpose: Executes a KMeans or GMM clustering routine

A master Makefile orchestrates the full end-to-end workflow, while you can also run each stage independently via their language-specific entrypoints.

## Getting Started

- Clone this repository

```bash
git clone https://github.com/ctoruno/eugpp-clustering.git
cd eugpp-clustering
```

- (Option A) Run the entire pipeline

```bash
make all
```

- (Option B) Run individual stages

```bash
make mice
make nlpca
make umap
make eda
make kmeans
make gauss
```

- (Option C) Run individual stages from their respective entrypoints

```bash
cd lib/R
Rscript main.R --mice --nlpca
```

```bash
cd lib/python 
uv run main.py --umap --eda --kmeans --gauss
```

## Repo Structure

All intermediate and final data outputs are stored under the data/ directory:

- `data/mice_imputations/` – Individual imputed datasets (5 imputations × 5 dimensions × 4 groups)
- `data/nlpca_results.csv` – Factor scores from the NLPCA analysis
- `data/umap_reductions/` – UMAP embeddings for visualization
- `data/kmeans_results/` – Cluster assignments from K-Means
- `data/gmm_results/` – Cluster assignments from Gaussian Mixture Models

Visualization assets live in `/viz`, organized by stage and cluster type.

```
.
├── data
│   ├── gmm_results
│   ├── kmeans_results
│   ├── mice_imputations
│   ├── nlpca_results.csv
│   └── umap_reductions
├── lib
│   ├── python
│   │   ├── main.py
│   │   ├── notebooks
│   │   │   └── clustering.ipynb
│   │   ├── pyproject.toml
│   │   ├── src
│   │   │   ├── __init__.py
│   │   │   ├── clustering.py
│   │   │   ├── config.py
│   │   │   └── umap.py
│   │   └── uv.lock
│   └── R
│       ├── main.R
│       ├── R.Rproj
│       ├── renv
│       │   ├── activate.R
│       │   └── settings.json
│       ├── renv.lock
│       └── src
│           ├── CFA.R
│           ├── config.R
│           ├── data_loading.R
│           ├── MICE.R
│           └── NLPCA.R
├── Makefile
├── metadata
│   ├── Clustering.md
│   ├── theoretical_outline.xlsx
│   └── UMAP.md
├── README.md
└── viz
    ├── gmm
    ├── kmeans
    ├── optimal_k
```

## Contact
For inqueries please contact Carlos Toruño (ctoruno@worldjusticeproject.org).