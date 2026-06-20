from app.config import MODEL_DIR, EMOTION_LABELS
from app.model import DistilBERTForMoodAndEmotions
from app.inference import predict


def load_model():
    model = DistilBERTForMoodAndEmotions()
    state_dict_path = MODEL_DIR / "best.pt"
    if not state_dict_path.exists():
        print(f"Error: no trained model found at {state_dict_path}. Run train.py first.")
        return None
    import torch
    state_dict = torch.load(state_dict_path, weights_only=True)
    model.load_state_dict(state_dict)
    model.eval()
    return model


def main():
    model = load_model()
    if model is None:
        return

    print("Ivy Mental — mood and emotion predictor")
    print("Type a diary entry (or 'quit' to exit).")
    print()

    while True:
        try:
            text = input("> ")
        except (EOFError, KeyboardInterrupt):
            print()
            break
        if text.strip().lower() == "quit":
            break
        if not text.strip():
            continue

        result = predict(model, text)
        mood = result["mood"]
        if mood >= 0.3:
            mood_label = "positive"
        elif mood <= -0.3:
            mood_label = "negative"
        else:
            mood_label = "neutral"

        print(f"\nMood: {mood:.2f} ({mood_label})")
        print("Emotions:")
        for label in EMOTION_LABELS:
            prob = result["emotions"][label]
            bar = "█" * int(prob * 20) + "░" * (20 - int(prob * 20))
            print(f"  {label:>10}: {prob:.2f} {bar}")
        print()


if __name__ == "__main__":
    main()
