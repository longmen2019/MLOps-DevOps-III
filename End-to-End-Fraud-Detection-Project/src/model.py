# Import os — provides tools for interacting with the operating system
# Useful for file path handling, directory navigation, and environment variable access
import os

# Import pandas — essential for data manipulation and analysis
# Commonly used for loading datasets, handling DataFrames, and performing preprocessing tasks
import pandas as pd

# Import seaborn — a statistical data visualization library built on top of matplotlib
# Provides high-level functions for creating attractive and informative plots (e.g., barplots, heatmaps)
import seaborn as sns

# Import matplotlib.pyplot — the core plotting interface of matplotlib
# Used for customizing plots, setting figure size, labels, titles, and displaying visualizations
import matplotlib.pyplot as plt

# Import train_test_split — a utility for splitting datasets into training and testing sets
# Helps evaluate model performance on unseen data
from sklearn.model_selection import train_test_split

# Import resample — used for upsampling or downsampling datasets
# Handy for handling class imbalance by replicating or reducing samples
from sklearn.utils import resample

# Import classification_report and confusion_matrix — tools for evaluating classification models
# Provide metrics like precision, recall, F1-score, and a matrix of predicted vs actual labels
from sklearn.metrics import classification_report, confusion_matrix

# Import LogisticRegression — a linear model for binary classification
# Often used as a baseline model for fraud detection and other classification tasks
from sklearn.linear_model import LogisticRegression

# Import pickle — a Python module for serializing and saving objects
# Useful for saving trained models to disk and loading them later for inference or reuse
import pickle

def load_processed_data(file_path):
    """
    Load the processed data from a CSV file.
    
    Parameters:
    file_path (str): Path to the processed data file.
    
    Returns:
    DataFrame: Loaded DataFrame.
    """

    # Read the CSV file from the specified path using pandas
    # This loads the processed data into a DataFrame for analysis or modeling
    return pd.read_csv(file_path)

def prepare_training_data(df):
    """
    Prepare the training data by downsampling the majority class.

    Parameters:
    df (DataFrame): The input DataFrame with features and target.

    Returns:
    Tuple: Downsampled training features (X_train_downsampled), 
           downsampled training target (y_train_downsampled),
           original test features (X_test_orig),
           original test target (y_test_orig).
    """

    # Separate features (X) and target (y)
    # 'X' includes all columns except 'Class', which is the label indicating fraud (1) or non-fraud (0)
    X = df.drop(columns='Class')
    y = df['Class']

    # Split the data into training and testing sets using stratified sampling
    # 'stratify=y' ensures that both sets maintain the original class distribution
    # 'test_size=0.2' reserves 20% of the data for testing
    X_train_orig, X_test_orig, y_train_orig, y_test_orig = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y)

    # Combine training features and target into a single DataFrame for easier manipulation
    train_data = X_train_orig.copy()
    train_data['Class'] = y_train_orig

    # Separate the majority class (non-fraud) and minority class (fraud)
    majority_class = train_data[train_data['Class'] == 0]
    minority_class = train_data[train_data['Class'] == 1]

    # Downsample the majority class to match the number of minority samples
    # 'replace=False' ensures sampling without replacement
    # 'random_state=42' ensures reproducibility
    majority_downsampled = resample(
        majority_class,
        replace=False,
        n_samples=len(minority_class),
        random_state=42
    )

    # Combine the downsampled majority class with the full minority class
    downsampled_train_data = pd.concat([majority_downsampled, minority_class])

    # Separate features and target from the downsampled training data
    X_train_downsampled = downsampled_train_data.drop(columns='Class')
    y_train_downsampled = downsampled_train_data['Class']

    # Return the downsampled training set and the original test set
    return X_train_downsampled, y_train_downsampled, X_test_orig, y_test_orig

def train_logistic_regression(X_train, y_train):
    """
    Train a logistic regression model.
    
    Parameters:
    X_train (DataFrame): Training features.
    y_train (Series): Training target.
    
    Returns:
    LogisticRegression: Trained logistic regression model.
    """

    # Initialize a logistic regression model using default hyperparameters
    # Logistic regression is a linear model commonly used for binary classification tasks like fraud detection
    log_reg = LogisticRegression()

    # Fit the model to the training data
    # This step learns the relationship between features and the target variable
    log_reg.fit(X_train, y_train)

    # Return the trained model for evaluation or prediction
    return log_reg

def save_model(model, directory, filename):
    """
    Save the trained model to a pickle file.
    
    Parameters:
    model: Trained model to save.
    directory (str): Directory to save the model.
    filename (str): Name of the pickle file.
    """

    # Check if the target directory exists; if not, create it
    # This ensures the save path is valid and avoids errors when writing the file
    if not os.path.exists(directory):
        os.makedirs(directory)

    # Construct the full file path by joining the directory and filename
    model_filepath = os.path.join(directory, filename)

    # Open the file in binary write mode and serialize the model using pickle
    # This saves the trained model object so it can be loaded later for inference or reuse
    with open(model_filepath, 'wb') as file:
        pickle.dump(model, file)

    # Print a confirmation message with the full save path
    print(f"Model saved to {model_filepath}")

def save_classification_report(y_true, y_pred, file_path):
    """
    Save the classification report as an image.
    
    Parameters:
    y_true (Series): True target values.
    y_pred (Series): Predicted target values.
    file_path (str): Path to save the classification report image.
    """

    # Generate a classification report as a dictionary
    # Includes precision, recall, f1-score, and support for each class
    report = classification_report(y_true, y_pred, output_dict=True)

    # Convert the report dictionary into a pandas DataFrame for easier plotting
    # Transpose to make metrics the columns and classes the rows
    report_df = pd.DataFrame(report).transpose()

    # Set the figure size for the heatmap
    plt.figure(figsize=(10, 6))

    # Plot a heatmap of the classification metrics (excluding 'accuracy' row and 'support' column)
    # 'annot=True' displays metric values in each cell
    # 'cmap="Blues"' sets the color palette
    # 'fmt=".2f"' formats the numbers to two decimal places
    sns.heatmap(report_df.iloc[:-1, :-1], annot=True, cmap='Blues', fmt='.2f')

    # Add a title to the heatmap for clarity
    plt.title('Classification Report')

    # Save the heatmap image to the specified file path
    plt.savefig(file_path)

    # Print confirmation message with the save location
    print(f"Classification report saved to {file_path}")

def plot_confusion_matrix(y_true, y_pred):
    """
    Plot the confusion matrix.
    
    Parameters:
    y_true (Series): True target values.
    y_pred (Series): Predicted target values.
    """

    # Generate the confusion matrix from true and predicted labels
    # This matrix summarizes correct and incorrect predictions across each class
    conf_matrix = confusion_matrix(y_true, y_pred)

    # Set the figure size to 8x6 inches for a clear and readable layout
    plt.figure(figsize=(8, 6))

    # Plot the confusion matrix as a heatmap using seaborn
    # 'annot=True' displays the count in each cell
    # 'fmt="d"' formats the annotations as integers
    # 'cmap="Blues"' sets the color palette
    # 'xticklabels' and 'yticklabels' label the axes with class names
    sns.heatmap(conf_matrix, annot=True, fmt='d', cmap='Blues', 
                xticklabels=['Non-Fraud', 'Fraud'], 
                yticklabels=['Non-Fraud', 'Fraud'])

    # Label the x-axis as 'Predicted' and y-axis as 'Actual'
    plt.xlabel('Predicted')
    plt.ylabel('Actual')

    # Add a title to the plot for context
    plt.title('Confusion Matrix')

    # Display the plot in the notebook or script output
    plt.show()

# Example usage:

# Load the processed dataset from disk
# This file should contain balanced or cleaned data ready for modeling
processed_data_path = 'data/processed/processed_data.csv'
df = load_processed_data(processed_data_path)
print("Data Loaded!")

# Split the data into training and testing sets
# Training data is downsampled to balance fraud and non-fraud classes
X_train_downsampled, y_train_downsampled, X_test_orig, y_test_orig = prepare_training_data(df)

# Train a logistic regression model using the downsampled training data
# This step fits the model to learn patterns that distinguish fraud from non-fraud
log_reg = train_logistic_regression(X_train_downsampled, y_train_downsampled)
print("Model Trained!")

# Use the trained model to make predictions on the original (imbalanced) test set
# This evaluates how well the model generalizes to unseen data
y_pred = log_reg.predict(X_test_orig)

# Visualize the confusion matrix to assess prediction accuracy
# Helps identify false positives and false negatives — critical in fraud detection
plot_confusion_matrix(y_test_orig, y_pred)

# Save the trained model to disk for future reuse or deployment
# The model is serialized as a .pkl file in the 'models' directory
save_model(log_reg, 'models', 'logistic_regression_model.pkl')

# Generate and save a visual classification report as a heatmap
# This includes precision, recall, and F1-score for each class
classification_report_path = 'artifacts/classification_report.jpeg'
save_classification_report(y_test_orig, y_pred, classification_report_path)
print("Report Saved!")
