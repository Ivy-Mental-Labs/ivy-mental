import torch
import torch.nn as nn
from transformers import DistilBertModel

from app.config import BASE_MODEL, NUM_EMOTIONS


class DistilBERTForMoodAndEmotions(nn.Module):
    def __init__(self):
        super().__init__()
        self.encoder = DistilBertModel.from_pretrained(BASE_MODEL)
        hidden_size = self.encoder.config.hidden_size
        self.mood_head = nn.Sequential(
            nn.Linear(hidden_size, 1),
            nn.Tanh(),
        )
        self.emotion_head = nn.Linear(hidden_size, NUM_EMOTIONS)

    def forward(self, input_ids, attention_mask):
        outputs = self.encoder(input_ids=input_ids, attention_mask=attention_mask)
        cls_embedding = outputs.last_hidden_state[:, 0, :]
        mood_logits = self.mood_head(cls_embedding)
        emotion_logits = self.emotion_head(cls_embedding)
        return mood_logits, emotion_logits
