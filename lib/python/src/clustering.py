import numpy as np
import pandas as pd
from sklearn.cluster import KMeans
from sklearn.mixture import GaussianMixture
from sklearn.metrics import silhouette_score
from sklearn.neighbors import NearestNeighbors
from sklearn.preprocessing import RobustScaler
from hdbscan import HDBSCAN
import matplotlib.pyplot as plt
import seaborn as sns

class EUGPP:
    """
    Class to perform clustering analysis on the EU GPP dataset.
    """

    def __init__(self, path2SP, group):
        """
        Initialize the EUGPP class with a specific group.
        Args:
            path2SP (str): Path to the EU-data local directory.
            group (str): The group to filter the data by.
        """

        self.group = group
        self.eugpp = pd.read_stata(
            f"{path2SP}/eu-gpp/1. Data/3. Merge/EU_GPP_2024.dta", 
            convert_categoricals = False
        ).set_index("country_year_id")
        self.eugpp = (
            self.eugpp
            .loc[self.eugpp["gend"] < 3]
        )
        self.nlpca = (
            pd.read_csv("../../data/nlpca_results.csv")
        ).set_index("country_year_id")
        self.nlpca = (
            self.nlpca
            .loc[(self.nlpca["group"] == self.group)]
        )
        self.features = (
            self.nlpca.copy()
            .drop(columns = ["group"])
        )
        self.features_reduced = (
            pd.read_csv(f"../../data/umap_reductions/umap_{self.group}_results.csv")
            .set_index("country_year_id")
        )
        self.features_normalized = RobustScaler().fit_transform(self.features)


    def get_corrs(self):
        """
        Get the correlation matrix for the features of a given group.
        """

        corr_matrix = self.features.corr()
        mask = np.triu(np.ones_like(corr_matrix, dtype=bool))

        f, ax = plt.subplots(figsize=(11, 9))
        cmap = sns.diverging_palette(230, 20, as_cmap=True)
        sns.heatmap(
            corr_matrix, 
            mask = mask, 
            cmap = cmap, 
            vmax = 1,
            vmin = -1, 
            center = 0,
            square = True,
            fmt    = ".2f", 
            annot  = True,
            annot_kws  = {"size": 8},
            linewidths = 0.5,
            cbar_kws   = {"shrink": 0.5}
        )
        ax.set_title(
            f"Correlation Matrix for Group {self.group}", 
            fontsize = 14, 
            pad = 12
        )
        plt.savefig(
            f"../../viz/feature_correlation/{self.group}_correlation_heatmap.png", 
            dpi = 100, 
            bbox_inches = "tight"
        )
        plt.close()


    def _get_inertia_silhouette(self, k):
        """
        Get inertia and silhouette score for KMeans clustering.
        Args:
            k (int): Number of clusters.
        Returns:
            dict: A dictionary containing inertia and silhouette score.
        """

        kmeans = KMeans(
            n_clusters   = k, 
            random_state = 1910
        )
        kmeans.fit(self.features)

        inertia = kmeans.inertia_
        if k > 1:
            si_score = silhouette_score(self.features, kmeans.labels_)
        else:
            si_score = None

        return {"inertia": inertia, "silhouette_score": si_score}
    

    def draw_elbow_silhouette(self):
        """
        Draw the elbow method and silhouette score plots for KMeans clustering.
        """

        optimal_k_data = [
            self._get_inertia_silhouette(k) 
            for k in range(1,11)
        ]

        fig, axs = plt.subplots(1, 2, figsize=(14, 5))
    
        # Elbow Method
        axs[0].plot(
            range(1,11), 
            [x["inertia"] for x in optimal_k_data], 
            marker = "o"
        )
        axs[0].set_title(f"Elbow Method for Group {self.group}")
        axs[0].set_xlabel("Number of Clusters (k)")
        axs[0].set_ylabel("Inertia")

        # Silhouette Score
        axs[1].plot(
            range(2, 11), 
            [x["silhouette_score"] for x in optimal_k_data[1:]], 
            marker = "o"
        )
        axs[1].set_title(f"Silhouette Scores for Group {self.group}")
        axs[1].set_xlabel("Number of Clusters (k)")
        axs[1].set_ylabel("Silhouette Score")

        plt.tight_layout()
        plt.savefig(
            f"../../viz/optimal_k/{self.group}_elbow_silhouette_KMEANS.png", 
            dpi = 100, 
            bbox_inches = "tight"
        )
        plt.close()

    
    def get_gauss_metrics(self):
        """
        Get AIC/BIC and silhouette scores for Gaussian Mixture Models.
        """

        bic_scores  = []
        aic_scores  = []
        silhouettes = [] 
        n_components_range = range(1, 11)

        for n in n_components_range:
            gmm = GaussianMixture(n_components=n, random_state=281299)
            gmm.fit(self.features_normalized)
            labels = gmm.predict(self.features_normalized)
            bic_scores.append(gmm.bic(self.features_normalized))
            aic_scores.append(gmm.aic(self.features_normalized))

            if n>1:
                silhouette_avg = silhouette_score(self.features_normalized, labels)
                silhouettes.append(silhouette_avg)

        # AIC/BIC Scores
        plt.figure(figsize=(8, 4))
        plt.plot(n_components_range, np.gradient(bic_scores), label="BIC", marker="o")
        plt.plot(n_components_range, np.gradient(aic_scores), label="AIC", marker="o")
        plt.xlabel("Number of Components")
        plt.ylabel("Score")
        plt.legend()
        plt.title(f"AIC/BIC Gradients for Group {self.group}")
        plt.savefig(
            f"../../viz/optimal_k/{self.group}_AIC_BIC.png", 
            dpi = 100, 
            bbox_inches = "tight"
        )
        plt.close()

        # Silhouette Score
        plt.figure(figsize=(8, 5))
        plt.plot(
            range(2, 11), 
            silhouettes,
            marker = "o"
        )
        plt.title(f"Silhouette Scores for Group {self.group}")
        plt.xlabel("Number of Clusters (k)")
        plt.ylabel("Silhouette Score")
        plt.savefig(
            f"../../viz/optimal_k/{self.group}_elbow_silhouette_GAUSS.png", 
            dpi = 100, 
            bbox_inches = "tight"
        )
        plt.close()


    def kmeans(self, n):
        """
        Perform KMeans clustering on the features of a given group.
        Args:
            n (int): Number of clusters.
        """

        kmeans = KMeans(
            n_clusters   = n, 
            random_state = 1910
        )
        kmeans.fit(self.features_normalized)
        kmean_labels = kmeans.fit_predict(self.features_normalized)

        self.nlpca["cluster_kmeans"] = kmean_labels
        self.nlpca.to_csv(
            f"../../data/kmeans_results/{self.group}_kmeans_results.csv"
        )
        print(self.nlpca.cluster_kmeans.value_counts())

        self.features_reduced["cluster_kmeans"] = kmean_labels
        sns.scatterplot(
            self.features_reduced,
            x = "umap_1",
            y = "umap_2",
            hue = "cluster_kmeans",
            palette = "deep"
        )
        plt.title(f"UMAP Projection of KMeans Clusters for Group {self.group}")
        plt.savefig(
            f"../../viz/kmeans/{self.group}_ncl_{n}.png", 
            dpi = 100, 
            bbox_inches = "tight"
        )
        plt.close()

        sns.pairplot(
            self.nlpca.drop("group", axis=1), 
            hue = "cluster_kmeans"
        )
        plt.title(f"Pairplot KMeans Clusters for Group {self.group}")
        plt.savefig(
            f"../../viz/kmeans/{self.group}_ncl_{n}_pairplot.png", 
            dpi = 100, 
            bbox_inches = "tight"
        )
        plt.close()

    
    def gaussian(self, n):

        gmm = GaussianMixture(
            n_components    = n, 
            covariance_type = "full", 
            random_state    = 1910
        )
        gmm.fit(self.features_normalized)
        gmm_labels = gmm.predict(self.features_normalized)

        self.nlpca["cluster_gmm"] = gmm_labels
        self.nlpca.to_csv(
            f"../../data/gmm_results/{self.group}_gmm_results.csv"
        )
        print(self.nlpca.cluster_gmm.value_counts())

        self.features_reduced["cluster_gmm"] = gmm_labels
        sns.scatterplot(
            self.features_reduced,
            x = "umap_1",
            y = "umap_2",
            hue = "cluster_gmm",
            palette = "deep"
        )
        plt.title(f"UMAP Projection of GMM Clusters for Group {self.group}")
        plt.savefig(
            f"../../viz/gmm/{self.group}_ncl_{n}.png", 
            dpi = 100, 
            bbox_inches = "tight"
        )
        plt.close()

        sns.pairplot(
            self.nlpca.drop("group", axis=1), 
            hue = "cluster_gmm"
        )
        plt.title(f"Pairplot GMM Clusters for Group {self.group}")
        plt.savefig(
            f"../../viz/gmm/{self.group}_ncl_{n}_pairplot.png", 
            dpi = 100, 
            bbox_inches = "tight"
        )
        plt.close()