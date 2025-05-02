.PHONY: all mice nlpca cluster

all: mice nlpca cluster

mice:
	@echo "Calling MICE (R) routine..."
	cd lib/R && Rscript main.R --mice

nlpca:
	@echo "Calling NLPCA (R) Routine..."
	cd lib/R && Rscript main.R --nlpca

cluster:
	@echo "Calling Clustering (Python) Routine..."
	cd lib/python && uv run main.py