# Import Streamlit — the core framework for building interactive web apps in Python
# Enables UI components like sliders, buttons, file uploads, and real-time updates
import streamlit as st

# Import time — provides time-related functions
# Useful for simulating loading delays or measuring execution time
import time

# Import pickle — used for loading serialized models or data objects
# Essential for deploying pre-trained models in your app
import pickle

# Import numpy — foundational library for numerical operations
# Often used for array manipulation and feeding data into models
import numpy as np

# Import pandas — powerful data analysis and manipulation library
# Commonly used for loading and displaying tabular data in the app
import pandas as pd

# Import Image from PIL (Python Imaging Library) — handles image loading and display
# Useful for showing logos, visualizations, or uploaded images in the app
from PIL import Image

# Load the trained logistic regression model
# This allows you to reuse the model for predictions in a Streamlit app or other deployment context

# Define the path to the saved model file
model_path = "models/logistic_regression_model.pkl"

# Open the model file in binary read mode
# 'rb' stands for "read binary" — required for loading pickle files
with open(model_path, "rb") as model_file:

    # Load the serialized model object using pickle
    # This restores the trained LogisticRegression instance for inference
    model = pickle.load(model_file)

# App Title — sets the main heading at the top of the Streamlit interface
st.title("💳 Welcome to CC Fraud Detection Platform")

# Subheading — prompts users to enter transaction details for fraud prediction
st.subheader("🔍 Enter your transaction details")

# Define user-friendly field names for input features
# These replace abstract names like V1, V2 with more intuitive labels
field_names = [
    "Amount", "Transaction Time", "Location Score", "Merchant Type", "Card Usage", 
    "Risk Factor", "Account Age", "Spending Pattern", "Alert Count"
]

# Initialize default values for each input field
# These will be used to populate sliders or number inputs with a starting value of 0
default_values = {name: 0 for name in field_names}

user_inputs = {}
cols = st.columns(3)
for idx , name in enumerate(field_names):
    with cols[idx % 3]:
        user_inputs[name] = st.text_input(name, value=str(default_values[name]))


# Create a dictionary to store user inputs
user_inputs = {}

# Arrange input fields into 3 columns for a cleaner, more organized layout
cols = st.columns(3)

# Loop through each field name and create a text input widget
# Loop through each field name and create a text input widget
for idx, name in enumerate(field_names):
    # Distribute fields evenly across the 3 columns using modulo indexing
    with cols[idx % 3]:
        # Create a text input for each field with a default value of "0"
        # Assign a unique key to avoid StreamlitDuplicateElementId errors
        # Store the input as a string in the user_inputs dictionary
        user_inputs[name] = st.text_input(
            label=name,
            value=str(default_values[name]),
            key=f"text_input_{idx}_{name}"  # Unique key using index and name
        )


# Prediction function — takes user inputs and returns a fraud prediction
def predict_fraud(inputs):
    # Convert the dictionary of user inputs into a NumPy array
    # Ensure all values are cast to float for compatibility with the model
    input_array = np.array([float(inputs[name]) for name in field_names]).reshape(1, -1)

    # Use the trained logistic regression model to make a prediction
    # The model returns 1 for fraud and 0 for non-fraud
    prediction = model.predict(input_array)

    # Return a human-readable label based on the prediction
    return "Fraud" if prediction[0] == 1 else "Not Fraud"

# Create two columns for side-by-side buttons
col1, col2 = st.columns([1, 1])

# Button to trigger fraud prediction
with col1:
    predict_button = st.button("🚀 Predict Transaction")

# Button to reset all input fields
with col2:
    reset_button = st.button("🔄 Reset Fields")

# If the reset button is clicked, rerun the app to clear all inputs
# This resets the session state and reinitializes default values
if reset_button:
    st.experimental_rerun()

# If the predict button is clicked, show a spinner and simulate progress
if predict_button:
    with st.spinner("Processing transaction..."):
        progress_bar = st.progress(0)

        # Simulate a short delay to mimic model processing
        for i in range(5):
            time.sleep(1)
            progress_bar.progress((i + 1) * 20)

        # Run the prediction function using user inputs
        result = predict_fraud(user_inputs)

        # Display the prediction result with a success message
        st.success(f"📝 Prediction: **{result}**")
