# Clustering

## K-Means Clustering

We use the Elbow method and the Silhouette Score to choose the best value for k:

1. Elbow Method: Plot the inertia (sum of squared distances to centroids) for different values of k. Then, look for the "elbow point" where inertia stops decreasing significantly.
2. Silhouette Score: Measures the compactness and separation of clusters. Higher values are better.

## DBSCAN

DBSCAN requires two key parameters:

- eps: The maximum distance between two points to be considered neighbors. Defines the radius of the neighborhood around a point. Points within this radius are considered neighbors. Affects how clusters are formed and how dense a region needs to be to qualify as a cluster. Small eps values results in a state where only very close points are grouped together, potentially resulting in many small clusters and a lot of noise. On the other hand, large eps values results in a state where wider neighborhoods may merge distinct clusters or fail to detect fine-grained structure.

- min_samples: The minimum number of points required to form a dense region (core point). Affects the size and compactness of clusters and how strict the algorithm is about defining clusters. Small min_samples values means that the process will tend to form more clusters, including small ones. Large min_samples values means that resulting clusters need more points to form, which can increase noise.

Results are highly sensitive to the definitions of these parameters. Therefore, parameter tuning is highly suggested. Incorrect parameter values may:
- Misclassify noise points as part of clusters.
- Fail to detect meaningful clusters (too few clusters or overly large clusters).
- Overfit or underfit the data structure.

Parameter tuning refers to the process of carefully selecting the hyperparameters of the DBSCAN algorithm — specifically eps and min_samples — to optimize clustering performance for a given dataset. These parameters are critical to the success of DBSCAN and can significantly influence the results, such as the number of clusters, the separation between clusters, and how well noise points are identified.

## HDBSCAN

HDBSCAN requires three parameters:

- min_cluster_size: Determines the minimum number of points required for a group to be considered a cluster. Larger values create fewer but larger clusters; smaller values result in more, smaller clusters.

- min_samples: The minimum number of points required to form a dense region (core point). Affects the size and compactness of clusters and how strict the algorithm is about defining clusters. Small min_samples values means that the process will tend to form more clusters, including small ones. Large min_samples values means that resulting clusters need more points to form, which can increase noise.

- eps: The maximum distance between two points to be considered neighbors. Defines the radius of the neighborhood around a point. Points within this radius are considered neighbors. Affects how clusters are formed and how dense a region needs to be to qualify as a cluster. Small eps values results in a state where only very close points are grouped together, potentially resulting in many small clusters and a lot of noise. On the other hand, large eps values results in a state where wider neighborhoods may merge distinct clusters or fail to detect fine-grained structure.

Results are highly sensitive to the definitions of these parameters. Therefore, parameter tuning is highly suggested. Incorrect parameter values may:
- Misclassify noise points as part of clusters.
- Fail to detect meaningful clusters (too few clusters or overly large clusters).
- Overfit or underfit the data structure.

Parameter tuning refers to the process of carefully selecting the hyperparameters of the HDBSCAN algorithm to optimize clustering performance for a given dataset. These parameters are critical to the success of DBSCAN and can significantly influence the results, such as the number of clusters, the separation between clusters, and how well noise points are identified.

The metric to measure the distances is also important:
- What it does: Specifies the distance metric used to calculate distances between points.
- The choice of metric affects how clusters are formed. For example:
    - Use euclidean for numerical data.
    - Use cosine for text or high-dimensional data.
    - Use mahalanobis when your features have dependencies or correlations.