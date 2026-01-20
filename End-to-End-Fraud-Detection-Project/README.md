
```markdown
# 💳 Credit Card Fraud Detection App

An end-to-end machine learning system for detecting fraudulent credit card transactions. This project combines robust data preprocessing, model training, and real-time prediction via a Streamlit dashboard — all containerized with Docker for reproducible deployment.

---

## 🚀 Features

- 📊 **Exploratory Data Analysis**: Correlation heatmaps, feature selection, and outlier investigation
- ⚖️ **Imbalance Handling**: Downsampling of majority class to improve fraud detection
- 🧠 **Model Benchmarking**: LazyPredict + manual F1 score comparison across classifiers
- 🏆 **Final Model**: NearestCentroid (FRAUDFIGHTER) with strong fraud recall
- 📈 **Permutation Importance**: Identifies top contributing features
- 🖥️ **Streamlit Dashboard**: Interactive UI for real-time predictions
- 🐳 **Dockerized Deployment**: Portable and reproducible app container

---

## 📁 Project Structure

```
CC-Fraud/
├── app.py                     # Streamlit app interface
├── src/                      # Modular ML pipeline components
│   ├── preprocess.py         # Data cleaning and feature selection
│   ├── train_model.py        # Model training and evaluation
│   └── predict.py            # Prediction logic
├── data/
│   ├── raw_data/             # Original dataset
│   └── processed/            # Cleaned and filtered data
├── models/                   # Saved model files (.pkl)
├── Dockerfile                # Docker container setup
├── requirements.txt          # Python dependencies
└── README.md                 # Project documentation
```

---

## 📦 Installation

### 1. Clone the repository
```bash
git clone http://github.com/longmen2019/MLOps-DevOps-III/blob/main/End-to-End-Fraud-Detection-Project/
cd CC-Fraud
```

### 2. Download the dataset
Download from [Kaggle](https://www.kaggle.com/datasets/mlg-ulb/creditcardfraud) and place `creditcard.csv` in:
```
data/raw_data/
```

### 3. Build and run with Docker
```bash
docker build -t cc-fraud-app .
docker run -p 8501:8501 cc-fraud-app
```

Then open your browser at:  
`http://localhost:8501`

---

## 🧪 Model Evaluation

- Stratified train/test split to preserve class distribution
- Downsampled training set to avoid bias
- Evaluated on original imbalanced test set
- Focused on **F1 score for Class 1 (fraud)** to minimize false negatives

---

## 📊 Feature Importance

Top contributing features:
- `V3`
- `V14`
- `V17`

Assessed using permutation importance with `scoring='f1'`.

---

## 🔐 Why False Negatives Matter

Misclassifying a fraudulent transaction as normal can result in significant financial loss.  
This project emphasizes minimizing false negatives to build trustworthy fraud detection systems.

---

## 📌 Future Improvements

- Real-time data ingestion
- Advanced feature engineering
- Cloud deployment via Azure or AWS
- Model monitoring and alerting

---

## 🙌 Acknowledgments

- Dataset: [Kaggle - Credit Card Fraud Detection](https://www.kaggle.com/datasets/mlg-ulb/creditcardfraud)
- Libraries: `scikit-learn`, `pandas`, `seaborn`, `Streamlit`, `Docker`, `LazyPredict`

---

