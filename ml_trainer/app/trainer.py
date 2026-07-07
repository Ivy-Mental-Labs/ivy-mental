import torch
import torch.nn as nn
from torch.optim import AdamW
from transformers import get_linear_schedule_with_warmup

from app.config import LEARNING_RATE, ENCODER_LR, NUM_EPOCHS, MOOD_LOSS_WEIGHT, EMOTION_LOSS_WEIGHT, MODEL_DIR, DEVICE


def train_model(model, train_loader, val_loader):
    device = torch.device(DEVICE)
    model.to(device)

    # Freeze all encoder parameters
    for param in model.encoder.parameters():
        param.requires_grad = False

    # Unfreeze only the last transformer layer of DistilBERT (layer index 5)
    for param in model.encoder.transformer.layer[-1].parameters():
        param.requires_grad = True

    # Parameter groups with differential learning rates
    last_layer_params = list(model.encoder.transformer.layer[-1].parameters())
    head_params = (
        list(model.shared_projection.parameters()) +
        list(model.mood_head.parameters()) +
        list(model.emotion_head.parameters())
    )

    optimizer = AdamW([
        {"params": last_layer_params, "lr": ENCODER_LR},
        {"params": head_params, "lr": LEARNING_RATE}
    ], weight_decay=0.01)
    total_steps = len(train_loader) * NUM_EPOCHS
    warmup_steps = int(0.1 * total_steps)
    scheduler = get_linear_schedule_with_warmup(optimizer, num_warmup_steps=warmup_steps, num_training_steps=total_steps)

    dataset = train_loader.dataset
    if hasattr(dataset, "indices") and hasattr(dataset, "dataset"):
        indices = dataset.indices
        labels = [dataset.dataset.emotion_labels[i] for i in indices]
    else:
        labels = dataset.emotion_labels
        
    labels = torch.tensor(labels, dtype=torch.float)
    pos_counts = labels.sum(dim=0)
    neg_counts = len(labels) - pos_counts
    pos_weight = neg_counts / torch.clamp(pos_counts, min=1.0)
    pos_weight = pos_weight.to(device)

    mood_criterion = nn.MSELoss()
    emotion_criterion = nn.BCEWithLogitsLoss(pos_weight=pos_weight)

    best_val_loss = float("inf")
    history = {"train_loss": [], "val_loss": []}

    for epoch in range(NUM_EPOCHS):
        model.train()
        train_loss = 0.0
        for batch in train_loader:
            input_ids = batch["input_ids"].to(device)
            attention_mask = batch["attention_mask"].to(device)
            mood_true = batch["mood"].to(device).unsqueeze(1)
            emotion_true = batch["emotion_labels"].to(device)

            optimizer.zero_grad()
            mood_pred, emotion_logits = model(input_ids, attention_mask)

            mood_loss = mood_criterion(mood_pred, mood_true)
            emotion_loss = emotion_criterion(emotion_logits, emotion_true)
            loss = MOOD_LOSS_WEIGHT * mood_loss + EMOTION_LOSS_WEIGHT * emotion_loss

            loss.backward()
            optimizer.step()
            scheduler.step()

            train_loss += loss.item()

        avg_train_loss = train_loss / len(train_loader)

        model.eval()
        val_loss = 0.0
        with torch.no_grad():
            for batch in val_loader:
                input_ids = batch["input_ids"].to(device)
                attention_mask = batch["attention_mask"].to(device)
                mood_true = batch["mood"].to(device).unsqueeze(1)
                emotion_true = batch["emotion_labels"].to(device)

                mood_pred, emotion_logits = model(input_ids, attention_mask)
                mood_loss = mood_criterion(mood_pred, mood_true)
                emotion_loss = emotion_criterion(emotion_logits, emotion_true)
                loss = MOOD_LOSS_WEIGHT * mood_loss + EMOTION_LOSS_WEIGHT * emotion_loss
                val_loss += loss.item()

        avg_val_loss = val_loss / len(val_loader)

        history["train_loss"].append(avg_train_loss)
        history["val_loss"].append(avg_val_loss)

        print(f"Epoch {epoch + 1}/{NUM_EPOCHS} | train_loss: {avg_train_loss:.4f} | val_loss: {avg_val_loss:.4f}")

        if avg_val_loss < best_val_loss:
            best_val_loss = avg_val_loss
            MODEL_DIR.mkdir(parents=True, exist_ok=True)
            torch.save(model.state_dict(), MODEL_DIR / "best.pt")
            print(f"  -> saved best model (val_loss: {best_val_loss:.4f})")

    torch.save(model.state_dict(), MODEL_DIR / "final.pt")
    print(f"Training complete. Final model saved to {MODEL_DIR / 'final.pt'}")

    return history
