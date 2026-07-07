import torch
import torch.nn as nn
from transformers import DistilBertModel

from app.config import BASE_MODEL, NUM_EMOTIONS


class DistilBERTForMoodAndEmotions(nn.Module):
    def __init__(self, freeze_encoder=False):
        super().__init__()
        self.encoder = DistilBertModel.from_pretrained(BASE_MODEL)
        if freeze_encoder:
            for param in self.encoder.parameters():
                param.requires_grad = False
        hidden_size = self.encoder.config.hidden_size
        self.shared_projection = nn.Sequential(
            nn.LayerNorm(hidden_size),
            nn.Linear(hidden_size, 256),
            nn.GELU(),
            nn.Dropout(0.2),
        )
        self.mood_head = nn.Sequential(
            nn.Linear(256, 64),
            nn.GELU(),
            nn.Dropout(0.1),
            nn.Linear(64, 1),
            nn.Tanh(),
        )
        self.emotion_head = nn.Sequential(
            nn.Linear(256, 128),
            nn.GELU(),
            nn.Dropout(0.1),
            nn.Linear(128, NUM_EMOTIONS),
        )

    def forward(self, input_ids, attention_mask):
        outputs = self.encoder(input_ids=input_ids, attention_mask=attention_mask)
        cls_embedding = outputs.last_hidden_state[:, 0, :]
        shared_features = self.shared_projection(cls_embedding)
        mood_logits = self.mood_head(shared_features)
        emotion_logits = self.emotion_head(shared_features)
        return mood_logits, emotion_logits
