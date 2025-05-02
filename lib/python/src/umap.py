import umap
import pandas as pd

class EUGPP:
    """
    Class to perform UMAP reduction on the EU GPP dataset.
    """

    def __init__ (self, group):
        """
        Initialize the EUGPP class with a specific group.
        Args:
            group (str): The group to filter the data by.
        """
        
        self.group = group
        self.data = (
            pd.read_csv("../../data/nlpca_results.csv")
            .set_index("country_year_id")
            .query(f"group == '{group}'")
            .drop(columns = ["group"])
        )


    def umap_reduction(self):
        """
        Perform UMAP reduction on the features of a given group.
        """

        umap_model = umap.UMAP(
            n_neighbors  = 5,  
            min_dist     = 0.1,
            metric       = "euclidean", 
            n_components = 2,
            n_jobs       = 1,
            random_state = 1910
        )

        features_reduced = umap_model.fit_transform(self.data)

        pd.DataFrame(
            features_reduced, 
            columns = ["umap_1", "umap_2"], 
            index   = self.data.index
        ).to_csv(
            f"../../data/umap_reductions/umap_{self.group}_results.csv"
        )
