import pandas as pd
import torch
from torch.utils.data import Dataset, DataLoader, random_split
from transformers import DistilBertTokenizerFast

from app.config import BASE_MODEL, MAX_LENGTH, EMOTION_LABELS, BATCH_SIZE, TRAIN_SPLIT, SEED


tokenizer = DistilBertTokenizerFast.from_pretrained(BASE_MODEL)


class DiaryDataset(Dataset):
    def __init__(self, texts, moods, emotion_labels):
        self.texts = texts
        self.moods = moods
        self.emotion_labels = emotion_labels

    def __len__(self):
        return len(self.texts)

    def __getitem__(self, idx):
        enc = tokenizer(
            self.texts[idx],
            max_length=MAX_LENGTH,
            padding="max_length",
            truncation=True,
            return_tensors="pt",
        )
        return {
            "input_ids": enc["input_ids"].squeeze(0),
            "attention_mask": enc["attention_mask"].squeeze(0),
            "mood": torch.tensor(self.moods[idx], dtype=torch.float),
            "emotion_labels": torch.tensor(self.emotion_labels[idx], dtype=torch.float),
        }


def load_csv(csv_path):
    df = pd.read_csv(csv_path)
    texts = df["diary_entry"].tolist()
    moods = df["mood"].tolist()
    emotion_labels = df[EMOTION_LABELS].values.tolist()
    return texts, moods, emotion_labels


def create_dataloaders(csv_path, batch_size=BATCH_SIZE, train_split=TRAIN_SPLIT):
    texts, moods, emotion_labels = load_csv(csv_path)
    dataset = DiaryDataset(texts, moods, emotion_labels)
    train_size = int(train_split * len(dataset))
    val_size = len(dataset) - train_size
    generator = torch.Generator().manual_seed(SEED)
    train_dataset, val_dataset = random_split(dataset, [train_size, val_size], generator=generator)
    train_loader = DataLoader(train_dataset, batch_size=batch_size, shuffle=True)
    val_loader = DataLoader(val_dataset, batch_size=batch_size, shuffle=False)
    return train_loader, val_loader


def create_eval_loader(csv_path, batch_size=BATCH_SIZE):
    texts, moods, emotion_labels = load_csv(csv_path)
    dataset = DiaryDataset(texts, moods, emotion_labels)
    return DataLoader(dataset, batch_size=batch_size, shuffle=False)
