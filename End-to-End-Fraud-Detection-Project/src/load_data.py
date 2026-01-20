# Import pandas — essential for data manipulation and analysis
import pandas as pd

# Import os — provides tools for interacting with the operating system, including file paths
import os

def load_data(file_name):
    """
    Load a CSV file from the 'data/raw_data' directory.

    Parameters:
    file_name (str): The name of the CSV file to load.

    Returns:
    DataFrame: The loaded data as a pandas DataFrame.
    """

    # Construct the full path to the data file using os.path.join for cross-platform compatibility
    data_path = os.path.join('data', 'raw_data', file_name)

    # Check if the file exists at the constructed path
    # Raise a clear error if the file is missing to prevent silent failures
    if not os.path.exists(data_path):
        raise FileNotFoundError(f"The file at {data_path} does not exist.")

    # Load the CSV file into a pandas DataFrame
    data = pd.read_csv(data_path)

    # Return the loaded data for further processing
    return data

# Example usage:
# Load the credit card fraud dataset from the raw data directory
data = load_data('creditcard.csv')
