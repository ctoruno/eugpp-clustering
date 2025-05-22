import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

class cldata:

    def __init__(self, method, path2SP):
        """
        Initialize the cldata class.
        Args:
            method (str): The clustering method used (e.g., "kmeans", "gmm").
            path2SP (str): Path to the SP data directory.
        """

        self.method = method
        self.groups = ["AA", "AB", "BA", "BB"]
        self.data = pd.concat([
            pd.read_csv(f"../../data/{method}_results/{group}_{method}_results.csv")
            for group in self.groups
        ], ignore_index = True).set_index("country_year_id")
        self.eugpp = pd.read_stata(
            f"{path2SP}/eu-gpp/1. Data/3. Merge/EU_GPP_2024.dta", 
            convert_categoricals = False
        ).set_index("country_year_id")
        self.outline = pd.read_excel("../../metadata/theoretical_outline.xlsx")
    

    def _get_gresults(self, pillar, group, master_data):
        """
        Get the results for a specific pillar and group.
        Args:
            pillar (str): The pillar to filter by.
            group (str): The group to filter by.
            master_data (pd.DataFrame): The master data containing the results.
        Returns:
            pd.DataFrame: A DataFrame containing the results for the specified pillar and group.
        """

        vars = (
            self.outline
            .loc[(self.outline["pillar"] == pillar) & ((self.outline)[group]), "target_var"]
            .to_list()
        )
        data_subset = (
            master_data.copy()
            .loc[master_data["group"] == group, ["group", f"cluster_{self.method}"] + vars]
            .groupby(["group", f"cluster_{self.method}"])
            .mean()
        )
        data_subset["pillar"] = pillar
        results = pd.melt(
            data_subset.reset_index(),
            id_vars=["pillar","group",f"cluster_{self.method}"],
            value_vars=vars,
            var_name="variable",
            value_name="value"
        )
        results["pillar"] = pillar

        sns.boxplot(
            data=results,
            y="value",
            x=f"cluster_{self.method}",
            hue=f"cluster_{self.method}",
            palette="vlag"
        )
        sns.stripplot(
            data=results,
            y="value",
            x=f"cluster_{self.method}",
            size=3, 
            color=".3"
        )
        if self.method == "kmeans":
            plt.suptitle(f"Distribution of scores K-Means Clusters for Group {group}")
        if self.method == "gmm":
            plt.suptitle(f"Distribution of scores GMM Clusters for Group {group}")
        plt.title(f"Pillar: {pillar}")

        plt.savefig(
            f"../../viz/{self.method}_profile/{group}_{pillar}_boxplot.png", 
            dpi = 100, 
            bbox_inches = "tight"
        )
        plt.close()

        return True
    

    def draw_boxplots(self):

        pillar_map = {
            "checks_D1"  : "Checks on Government Powers",
            "checks_D2"  : "Checks on Government Powers",
            "frights_D1" : "Fundamental Rights & Civic Participation",
            "frights_D2" : "Fundamental Rights & Civic Participation",
            "justice_D1" : "Justice & Law Enforcement",
            "justice_D2" : "Justice & Law Enforcement",
            "corrup_D1"  : "Transparency & Control of Corruption",
            "corrup_D2"  : "Transparency & Control of Corruption",
            "corrup_D3"  : "Transparency & Control of Corruption",
            "trust_D1"   : "Trust in Institutions"
        }
        
        outline_vars = list(set(self.outline.target_var))
        master_data = (
            self.data
            .merge(
                self.eugpp.loc[:, outline_vars],
                right_index=True,
                left_index=True,
                how="left"
            )
        )
        master_data[outline_vars] = master_data[outline_vars].replace([98,99], np.nan)

        gresults_list = [
            self._get_gresults(pillar, group, master_data)
            for pillar in list(set(pillar_map.values()))
            for group in self.groups
        ]

        return gresults_list
