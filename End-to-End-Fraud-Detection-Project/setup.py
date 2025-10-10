from setuptools import find_packages, setup

# Define the package metadata and configuration
setup(
    # Name of the package — avoid spaces for compatibility with PyPI and pip
    name="cc_fraud_detection",

    # Initial version number — follow semantic versioning (major.minor.patch)
    version="0.0.1",

    # Author information
    author="Long Men",
    author_email="men_long@yahoo.com",

    # Automatically discover all packages and subpackages
    packages=find_packages(),

    # List of required dependencies — add actual libraries used in your project
    install_requires=[
        "pandas",
        "numpy",
        "matplotlib",
        "seaborn",
        "scikit-learn"
    ],
)
