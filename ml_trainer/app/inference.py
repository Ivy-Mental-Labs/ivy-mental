import torch
import torch.nn.functional as F

from app.config import EMOTION_LABELS, DEVICE
from app.dataset import tokenizer


def predict(model, text):
    model.eval()
    device = torch.device(DEVICE)
    model.to(device)

    enc = tokenizer(
        text,
        max_length=128,
        padding="max_length",
        truncation=True,
        return_tensors="pt",
    )
    input_ids = enc["input_ids"].to(device)
    attention_mask = enc["attention_mask"].to(device)

    with torch.no_grad():
        mood_logits, emotion_logits = model(input_ids, attention_mask)

    mood = mood_logits.item()
    emotion_probs = F.sigmoid(emotion_logits).squeeze(0).tolist()
    emotions = {label: round(prob, 4) for label, prob in zip(EMOTION_LABELS, emotion_probs)}

    return {"mood": round(mood, 4), "emotions": emotions}
