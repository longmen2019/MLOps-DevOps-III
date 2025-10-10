# Import Path from pathlib for cross-platform file and directory handling
from pathlib import Path

# Import logging to provide timestamped feedback during execution
import logging

# Import os for checking file size and existence
import os

# Configure logging format to include timestamp and message
logging.basicConfig(level=logging.INFO, format='[%(asctime)s]: %(message)s:')

# Define a list of all file paths to be created
file_paths = [
    ".github/workflows/main_ccapp.yml",                  # GitHub Actions workflow for main app
    ".github/workflows/train-deploy.yml",                # GitHub Actions workflow for training and deployment
    "artifacts/classification_report.jpeg",              # Output image for classification report
    "data/processed/processed_data.csv",                 # Cleaned dataset
    "data/raw_data/creditcard.csv",                      # Raw input data
    "docs/data.md",                                      # Documentation about the dataset
    "models/logistic_regression_model.pkl",              # Serialized ML model
    "notebooks/credit-card-fraud-detection.ipynb",       # Jupyter notebook for EDA and modeling
    "src/data_prep.py",                                  # Script for data preprocessing
    "src/feat_eng.py",                                   # Script for feature engineering
    "src/load_data.py",                                  # Script for loading data
    "src/model.py",                                      # Script for training and evaluating model
    "Dockerfile",                                        # Docker configuration for containerization
    "README.md",                                         # Project overview and instructions
    "app.py",                                            # Main application entry point
    "requirements.txt",                                  # Python dependencies
    "setup.py"                                           # Packaging and installation script
]

# Loop through each file path in the list
for path_str in file_paths:
    path = Path(path_str)  # Convert string to Path object for better path manipulation

    # Check if the parent directory exists; if not, create it
    if not path.parent.exists():
        path.parent.mkdir(parents=True, exist_ok=True)  # Create all necessary parent directories
        logging.info(f"Created directory: {path.parent}")  # Log directory creation

    # Check if the file doesn't exist or is empty
    if not path.exists() or path.stat().st_size == 0:
        path.touch()  # Create an empty file
        logging.info(f"Created empty file: {path}")  # Log file creation
    else:
        logging.info(f"File already exists: {path}")  # Log that the file already exists