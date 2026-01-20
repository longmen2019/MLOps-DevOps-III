# Import pandas — a powerful library for data manipulation and analysis
# Commonly used for loading datasets, handling DataFrames, and performing preprocessing tasks
import pandas as pd

# Import seaborn — a statistical data visualization library built on top of matplotlib
# Provides high-level functions for creating attractive and informative plots (e.g., barplots, heatmaps)
import seaborn as sns

# Import matplotlib.pyplot — the core plotting interface of matplotlib
# Used for customizing plots, setting figure size, labels, titles, and displaying visualizations
import matplotlib.pyplot as plt

# Import RandomUnderSampler from imbalanced-learn — a tool for handling class imbalance
# Randomly downsamples the majority class to balance the dataset, improving model fairness and performance
from imblearn.under_sampling import RandomUnderSampler

# Import os — a standard Python library for interacting with the operating system
# Useful for file path handling, directory navigation, and environment variable access
import os

def preprocess_data(df):
    """
    Preprocess the data by performing undersampling and saving the processed data.
    
    Parameters:
    df (DataFrame): The input DataFrame to preprocess.
    
    Returns:
    DataFrame: The downsampled DataFrame.
    """

    # Separate features (X) and target (y)
    # 'X' includes all columns except 'Class', which is the label indicating fraud (1) or non-fraud (0)
    X = df.drop('Class', axis=1)

    # 'y' contains only the 'Class' column — the target variable for classification
    y = df['Class']

    # Initialize RandomUnderSampler to balance the dataset by reducing the majority class
    # 'random_state=42' ensures reproducibility of the sampling process
    rus = RandomUnderSampler(random_state=42)

    # Apply undersampling to the dataset
    # This returns a new set of features and labels with balanced class distribution
    X_resampled, y_resampled = rus.fit_resample(X, y)

    # Convert the resampled features and labels back into a single DataFrame
    # pd.DataFrame(X_resampled, columns=X.columns) restores column names for features
    # pd.DataFrame(y_resampled, columns=['Class']) ensures the target column is labeled correctly
    # pd.concat(..., axis=1) merges features and target side-by-side
    downsampled_df = pd.concat([
        pd.DataFrame(X_resampled, columns=X.columns),
        pd.DataFrame(y_resampled, columns=['Class'])
    ], axis=1)

    # Return the final downsampled DataFrame for further modeling or analysis
    return downsampled_df

def save_processed_data(df, file_path):
    """
    Save the processed data to a CSV file.
    
    Parameters:
    df (DataFrame): The DataFrame to save.
    file_path (str): The path to save the CSV file.
    """

    # Export the DataFrame to a CSV file at the specified path
    # 'index=False' prevents pandas from writing row indices into the file
    df.to_csv(file_path, index=False)

    # Print a confirmation message to let the user know the file was saved successfully
    print(f"Processed data saved to {file_path}")

def plot_heatmap(df, file_path):
    """
    Create and save a heatmap of the correlation matrix of the DataFrame.
    
    Parameters:
    df (DataFrame): The input DataFrame to plot the heatmap.
    file_path (str): The path to save the heatmap image.
    """

    # Override the input file_path to ensure the heatmap is saved in the 'artifacts' directory
    # This hardcoded path ensures consistency but ignores the function's file_path argument
    file_path = 'artifacts/heatmap.jpeg'

    # Set the figure size to 16x9 inches for a wide, readable layout
    plt.figure(figsize=(16, 9))

    # Compute and plot the correlation matrix as a heatmap
    # 'df.corr()' calculates pairwise correlations between numeric columns
    # 'annot=True' displays the correlation values inside each cell
    sns.heatmap(df.corr(), annot=True)

    # Save the heatmap image to the specified file path
    plt.savefig(file_path)

    # Print confirmation message with the save location
    print(f"Heatmap saved to {file_path}")

# Example usage:

# Load the raw credit card transaction data from CSV
# This dataset contains anonymized features and a 'Class' column indicating fraud (1) or non-fraud (0)
data_path = 'data/raw_data/creditcard.csv'
df = pd.read_csv(data_path)

# Preprocess the data by applying RandomUnderSampler to balance the class distribution
# This step reduces the majority class to match the minority class, improving model fairness
downsampled_df = preprocess_data(df)

# Save the original (unprocessed) data to a new CSV file for reference or backup
# Note: This line saves 'df', not the downsampled version — consider saving 'downsampled_df' instead if intended
processed_data_path = 'data/processed/processed_data.csv'
save_processed_data(df, processed_data_path)

# Plot and save a heatmap of feature correlations using the downsampled data
# This helps visualize relationships between features and identify potential multicollinearity
heatmap_path = 'artifacts/heatmap.jpeg'
plot_heatmap(downsampled_df, heatmap_path)
