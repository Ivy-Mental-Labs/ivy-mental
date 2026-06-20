from pathlib import Path


BASE_MODEL = "distilbert-base-uncased"
MAX_LENGTH = 128
EMOTION_LABELS = ["happy", "sad", "satisfied", "proud", "anxious", "angry", "afraid", "jealous"]
NUM_EMOTIONS = len(EMOTION_LABELS)
BATCH_SIZE = 16
LEARNING_RATE = 2e-5
NUM_EPOCHS = 10
TRAIN_SPLIT = 0.8
MODEL_DIR = Path("models")
MOOD_LOSS_WEIGHT = 1.0
EMOTION_LOSS_WEIGHT = 1.0
SEED = 42
DEVICE = "cpu"
