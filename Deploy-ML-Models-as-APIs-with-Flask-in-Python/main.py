# Import the pickle module for saving and loading Python objects (like models or scalers)
import pickle  

# Import Flask framework and utilities for building web APIs
from flask import Flask, request, jsonify  

# Import NumPy for numerical operations and array handling
import numpy as np  

# Import pandas for data manipulation and analysis
import pandas as pd  

# Initialize a Flask application instance
app = Flask(__name__)

# Load the trained machine learning model from a serialized file
with open("diabetes_model.pkl", "rb") as model_file:   
    loaded_model = pickle.load(model_file)

# Load the scaler (used for feature normalization) from a serialized file
with open("scaler.pkl", "rb") as scaler_file:          
    loaded_scaler = pickle.load(scaler_file)

# Define a route for the root URL ("/") of the application
@app.route("/")
def home():
    # When someone visits the root URL, return a simple message
    return "Diabetes Prediction App is running"

# Define a route for making predictions via POST requests
@app.route("/predict", methods=["POST"])
def predict():
    try:
        # Get the JSON data sent in the API request body
        data = request.get_json()

        # Check if input data is provided
        if not data:
            # If no data is provided, return an error message with status code 400
            return jsonify({"error": "Input data not provided"}), 400  

        # Convert the JSON data into a pandas DataFrame (needed for scaler/model input)
        input_data = pd.DataFrame([data])

        # Define the required columns that must be present in the input
        required_columns = [
            "Pregnancies", "Glucose", "BloodPressure", "SkinThickness",
            "Insulin", "BMI", "DiabetesPedigreeFunction", "Age"
        ]

        # Check if all required columns are present in the input data
        if not all(col in input_data.columns for col in required_columns):
            return jsonify({
                "error": f"Required columns missing. Required columns: {required_columns}"
            }), 400  

        # Scale the input data using the preloaded scaler
        scaled_data = loaded_scaler.transform(input_data)

        # Make a prediction using the preloaded model
        prediction = loaded_model.predict(scaled_data)

        # Format the response: 1 means Diabetes, 0 means No Diabetes
        response = {
            "prediction": "Diabetes" if prediction[0] == 1 else "No Diabetes"
        }

        # Return the prediction as JSON
        return jsonify(response)

    except Exception as e:
        # Catch any unexpected errors and return a generic error message
        return jsonify({"error": str(e)}), 500



if __name__=="__main__":
    app.run(debug=True)

