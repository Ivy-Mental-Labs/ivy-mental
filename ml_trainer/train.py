from app.config import MODEL_DIR
from app.model import DistilBERTForMoodAndEmotions
from app.dataset import create_dataloaders
from app.trainer import train_model


def main():
    print("Loading data...")
    train_loader, val_loader = create_dataloaders("data/sample.csv")

    print(f"Initializing model...")
    model = DistilBERTForMoodAndEmotions()

    print("Starting training...")
    train_model(model, train_loader, val_loader)

    tokenizer_path = MODEL_DIR / "tokenizer"
    from app.dataset import tokenizer
    tokenizer.save_pretrained(str(tokenizer_path))
    print(f"Tokenizer saved to {tokenizer_path}")


if __name__ == "__main__":
    main()
