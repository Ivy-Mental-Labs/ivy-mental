import torch

from app.config import MODEL_DIR, EMOTION_LABELS
from app.model import DistilBERTForMoodAndEmotions
from app.dataset import create_eval_loader
from app.evaluate import evaluate_model


def main():
    model = DistilBERTForMoodAndEmotions()
    state_dict_path = MODEL_DIR / "best.pt"
    if not state_dict_path.exists():
        print(f"Error: no trained model found at {state_dict_path}. Run train.py first.")
        return
    state_dict = torch.load(state_dict_path, weights_only=True)
    model.load_state_dict(state_dict)
    model.eval()

    eval_loader = create_eval_loader("data/sample_eval.csv")

    metrics = evaluate_model(model, eval_loader)

    print("Mood Prediction:")
    print(f"  MAE:  {metrics['mood_mae']:.4f}")
    print(f"  RMSE: {metrics['mood_rmse']:.4f}")
    print(f"  R²:   {metrics['mood_r2']:.4f}")
    print()
    print("Emotion Predictions (F1 scores):")
    for label in EMOTION_LABELS:
        print(f"  {label:>10}: {metrics['emotion_f1'][label]:.4f}")
    print(f"  {'macro':>10}: {metrics['emotion_f1']['macro']:.4f}")


if __name__ == "__main__":
    main()
