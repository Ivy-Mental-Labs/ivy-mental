from pathlib import Path

import torch

from app.config import MODEL_DIR
from app.model import DistilBERTForMoodAndEmotions


def export_to_onnx():
    model = DistilBERTForMoodAndEmotions()
    state_dict_path = MODEL_DIR / "best.pt"
    if not state_dict_path.exists():
        print(f"Error: no trained model found at {state_dict_path}. Run train.py first.")
        return

    state_dict = torch.load(state_dict_path, weights_only=True)
    model.load_state_dict(state_dict)
    model.eval()

    dummy_input_ids = torch.randint(0, 30522, (1, 128))
    dummy_attention_mask = torch.ones(1, 128, dtype=torch.long)

    output_path = MODEL_DIR / "model.onnx"
    MODEL_DIR.mkdir(parents=True, exist_ok=True)

    torch.onnx.export(
        model,
        (dummy_input_ids, dummy_attention_mask),
        str(output_path),
        input_names=["input_ids", "attention_mask"],
        output_names=["mood", "emotions"],
        dynamic_axes={
            "input_ids": {0: "batch_size"},
            "attention_mask": {0: "batch_size"},
            "mood": {0: "batch_size"},
            "emotions": {0: "batch_size"},
        },
        opset_version=14,
    )
    print(f"ONNX model exported to {output_path}")


if __name__ == "__main__":
    export_to_onnx()
