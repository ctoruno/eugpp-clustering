.PHONY: all mice nlpca umap eda kmeans gauss

all: mice nlpca umap eda kmeans gauss

mice:
	@echo "Calling MICE (R) routine..."
	cd lib/R && Rscript main.R --mice

nlpca:
	@echo "Calling NLPCA (R) Routine..."
	cd lib/R && Rscript main.R --nlpca

umap:
	@echo "Calling UMAP Reduction (Python) Routine..."
	cd lib/python && uv run main.py --umap

eda:
	@echo "Calling EDA (Python) Routine..."
	cd lib/python && uv run main.py --eda

kmeans:
	@echo "Calling KMEANS Clustering (Python) Routine..."
	cd lib/python && uv run main.py --kmeans

gauss:
	@echo "Calling GMM Clustering (Python) Routine..."
	cd lib/python && uv run main.py --gauss