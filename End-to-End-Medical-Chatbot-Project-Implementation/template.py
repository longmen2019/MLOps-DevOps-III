# Import standard libraries for file system operations and logging
import os
from pathlib import Path
import logging

# Configure logging to show timestamps and messages in a clean format
logging.basicConfig(level=logging.INFO, format='[%(asctime)s]: %(message)s:')

# Define a list of file paths to be created if they don't exist
list_of_files = [
    "src/__init__.py",              # Initializes the src module
    "src/helper.py",                # Placeholder for helper functions
    "src/prompt.py",                # Placeholder for prompt engineering logic
    ".env",                         # Environment variable file
    "setup.py",                     # Setup script for packaging (optional)
    "app.py",                       # Main application entry point
    "research/trials.ipynb",       # Jupyter notebook for experimentation
    "test.py"                       # Unit test or script for testing
]

# Loop through each file path in the list
for filepath in list_of_files:
    filepath = Path(filepath)  # Convert string to Path object for cross-platform compatibility
    filedir, filename = os.path.split(filepath)  # Split into directory and filename

    # If the file is inside a directory, create the directory if it doesn't exist
    if filedir != "":
        os.makedirs(filedir, exist_ok=True)  # Create directory recursively
        logging.info(f"Creating directory; {filedir} for the file: {filename}")

    # If the file doesn't exist or is empty, create it as an empty file
    if (not os.path.exists(filepath)) or (os.path.getsize(filepath) == 0):
        with open(filepath, "w") as f:
            pass  # Create an empty file
        logging.info(f"Creating empty file: {filepath}")

    # If the file already exists and is non-empty, log that it's already present
    else:
        logging.info(f"{filename} already exists")
