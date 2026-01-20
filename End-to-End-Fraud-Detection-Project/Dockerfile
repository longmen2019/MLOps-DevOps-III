# Use the official Python 3.11 image as the base for the container
# This includes Python and pip, but no extra packages
FROM python:3.11

# Set the working directory inside the container to /app
# All subsequent commands will run from this directory
WORKDIR /app

# Copy all files from your local project directory into the container's /app directory
COPY . /app

# Update the container's package index (Debian-based) — useful if you plan to install system packages
RUN apt update -y

# Update again and install Python dependencies listed in requirements.txt
# This sets up your app's environment with pandas, scikit-learn, streamlit, etc.
RUN apt-get update && pip install -r requirements.txt

# Define the default command to run when the container starts
# This launches your Streamlit app on port 8501 and binds it to all network interfaces
CMD ["streamlit", "run", "app.py", "--server.port=8501", "--server.address=0.0.0.0"]
