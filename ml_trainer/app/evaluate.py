import torch
import numpy as np
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score, f1_score

from app.config import EMOTION_LABELS, DEVICE


def evaluate_model(model, dataloader):
    device = torch.device(DEVICE)
    model.to(device)
    model.eval()

    all_mood_true = []
    all_mood_pred = []
    all_emotion_true = []
    all_emotion_pred = []

    with torch.no_grad():
        for batch in dataloader:
            input_ids = batch["input_ids"].to(device)
            attention_mask = batch["attention_mask"].to(device)

            mood_pred, emotion_logits = model(input_ids, attention_mask)

            all_mood_true.extend(batch["mood"].cpu().numpy())
            all_mood_pred.extend(mood_pred.cpu().numpy())
            all_emotion_true.extend(batch["emotion_labels"].cpu().numpy())
            all_emotion_pred.extend(torch.sigmoid(emotion_logits).cpu().numpy())

    mood_true = np.array(all_mood_true).flatten()
    mood_pred = np.array(all_mood_pred).flatten()
    emotion_true = np.array(all_emotion_true)
    emotion_pred = np.array(all_emotion_pred)

    mood_mae = mean_absolute_error(mood_true, mood_pred)
    mood_rmse = np.sqrt(mean_squared_error(mood_true, mood_pred))
    mood_r2 = r2_score(mood_true, mood_pred)

    emotion_pred_binary = np.zeros_like(emotion_pred)
    emotion_f1 = {}
    thresholds = {}
    for i, label in enumerate(EMOTION_LABELS):
        best_t = 0.5
        best_f1 = 0.0
        for t in np.arange(0.1, 0.9, 0.05):
            preds_t = (emotion_pred[:, i] >= t).astype(int)
            score = f1_score(emotion_true[:, i], preds_t, zero_division=0)
            if score > best_f1:
                best_f1 = score
                best_t = t
        emotion_f1[label] = best_f1
        thresholds[label] = best_t
        emotion_pred_binary[:, i] = (emotion_pred[:, i] >= best_t).astype(int)
    emotion_f1["macro"] = f1_score(emotion_true, emotion_pred_binary, average="macro", zero_division=0)

    return {
        "mood_mae": mood_mae,
        "mood_rmse": mood_rmse,
        "mood_r2": mood_r2,
        "emotion_f1": emotion_f1,
        "thresholds": thresholds,
    }
