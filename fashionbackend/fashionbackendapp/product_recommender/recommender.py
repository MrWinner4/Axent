import joblib
import os

MODEL_PATH = 'recommender_model.pkl'

def save_model(model, path=MODEL_PATH):
    """
    Save the trained model to a file.
    """
    joblib.dump(model, path)

def load_model(path=MODEL_PATH):
    """
    Load the trained model from a file.
    """
    if os.path.exists(path):
        return joblib.load(path)
    else:
        raise FileNotFoundError(f"Model file not found at {path}")