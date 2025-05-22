"""
Main script for running the clustering pipeline.
"""

import os
import time
import argparse
import logging
import warnings

from src import config
from src import umap
from src import clustering
from src import profiling

warnings.simplefilter(action='ignore', category=FutureWarning)

logging.basicConfig(
    level  = logging.INFO, 
    # format = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    format = '%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def main(args):
    start_time = time.time()

    path2SP = config.get_EUpath()
    groups = ["AA", "AB", "BA", "BB"]
    
    if args.all or args.umap:
        logger.info("Performing UMAP reduction...")
        os.makedirs(
            "../../data/umap_reductions", exist_ok=True
        )
        for g in groups:
            logger.info(f"Running UMAP reduction for group {g}...")
            umap.EUGPP(group = g).umap_reduction()
    
    if args.all or args.eda:
        logger.info("Performing EDA routines...")
        os.makedirs(
            "../../viz/feature_correlation", exist_ok=True
        )
        os.makedirs(
            "../../viz/optimal_k", exist_ok=True
        )

        for g in groups:
            eugpp_subsample = clustering.EUGPP(path2SP=path2SP, group=g)

            logger.info(f"Getting correlations for group {g}...")
            eugpp_subsample.get_corrs()

            logger.info(f"Estimating optimal K for group {g}...")
            eugpp_subsample.draw_elbow_silhouette()

            logger.info(f"Estimating optimal K (Gaussian Mixture) for group {g}...")
            eugpp_subsample.get_gauss_metrics()

    if args.all or args.kmeans:
        logger.info("Performing KMeans Clustering...")
        os.makedirs(
            "../../data/kmeans_results", exist_ok=True
        )
        os.makedirs(
            "../../viz/kmeans", exist_ok=True
        )

        # Select optimal K for each group
        # based on the elbow method and silhouette score from the EDA stage
        optimal_k = {
            "AA": 3,
            "AB": 3,
            "BA": 5,
            "BB": 4
        }

        for g in groups:
            logger.info("+++++++++++++++++++++++++++++++++++++++++++++")
            logger.info(f"[ITERATION] Running KMeans for group {g}...")
            logger.info("+++++++++++++++++++++++++++++++++++++++++++++")
            eugpp_subsample = clustering.EUGPP(path2SP=path2SP, group=g)
            eugpp_subsample.kmeans(optimal_k[g])

    if args.all or args.gauss:
        logger.info("Performing Gaussian Mixture Clustering...")
        os.makedirs(
            "../../data/gmm_results", exist_ok=True
        )
        os.makedirs(
            "../../viz/gmm", exist_ok=True
        )

        # Select optimal K for each group
        # based on the AIC/BIC gradients and silhouette score from the EDA stage
        optimal_k = {
            "AA": 3,
            "AB": 3,
            "BA": 4,
            "BB": 4
        }

        for g in groups:
            logger.info("+++++++++++++++++++++++++++++++++++++++++++++++++++++++")
            logger.info(f"[ITERATION] Running Gaussian Mixture for group {g}...")
            logger.info("+++++++++++++++++++++++++++++++++++++++++++++++++++++++")
            eugpp_subsample = clustering.EUGPP(path2SP=path2SP, group=g)
            eugpp_subsample.gaussian(optimal_k[g])
    
    if args.all or args.profile:
        for method in ["kmeans", "gmm"]:
            logger.info(f"Performing Profiling for {method}...")
            os.makedirs(
                f"../../viz/{method}_profile", exist_ok=True
            )
            profiling.cldata(method, path2SP).draw_boxplots()
        
    logger.info(f"Pipeline completed in {time.time() - start_time:.2f} seconds")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description = "Run the Clustering pipeline")
    parser.add_argument(
        "--all", 
        action = "store_true", 
        help   = "Run entire pipeline"
    )
    parser.add_argument(
        "--umap", 
        action = "store_true", 
        help   = "Run UMAP reduction"
    )
    parser.add_argument(
        "--eda", 
        action = "store_true", 
        help   = "Perform exploratory data analysis"
    )
    parser.add_argument(
        "--kmeans", 
        action = "store_true",
        help   = "Perform KMEANS clustering"
    )
    parser.add_argument(
        "--gauss", 
        action = "store_true",
        help   = "Perform Gaussian Mixture clustering"
    )
    parser.add_argument(
        "--profile", 
        action = "store_true",
        help   = "Perform Profiling of cluster results"
    )
    args = parser.parse_args()
    
    if not any(vars(args).values()):
        args.all = True
    
    main(args)
