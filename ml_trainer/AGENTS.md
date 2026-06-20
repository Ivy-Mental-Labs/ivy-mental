# Agents instructions — ml_trainer

## Project conventions

- **Language**: Python 3.11+
- **Package manager**: `uv` (not pip, not poetry)
- **Framework**: PyTorch + HuggingFace Transformers
- **Mobile export**: ONNX via Optimum
- **Code style**: No comments in code; use descriptive variable/function names

## Key commands

```bash
uv add <pkg>  # add a dependency
uv sync  # install deps from pyproject.toml + uv.lock
.venv/bin/python3 <script.py>  # run any script in the project root (use this instead of uv run)
```

## Project structure

```
ml_trainer/
├── app/              # Library code (model, dataset, trainer, inference, etc.)
├── data/             # CSV datasets (sample.csv, sample_eval.csv)
├── models/           # Trained model output (PyTorch .pt + ONNX .onnx)
├── train.py          # Script 1: train from CSV → model
├── evaluate.py       # Script 2: evaluate model on CSV → metrics
├── chat.py           # Script 3: interactive CLI
└── export_onnx.py    # Export PyTorch model to ONNX
```

## Model architecture

- **Encoder**: `distilbert-base-uncased` (frozen or fine-tuned)
- **Mood head**: `Linear(768 → 1)` + `tanh` → output in [-1, 1]
- **Emotion head**: `Linear(768 → 8)` → output logits, trained with `BCEWithLogitsLoss`
- **Loss**: `mood_weight * MSE(mood) + emotion_weight * BCE(emotions)`

Default weights: mood=1.0, emotion=1.0.

## Dataset columns

`diary_entry` (str), `mood` (float -1..1), `happy|sad|satisfied|proud|anxious|angry|afraid|jealous` (int 0/1).

## When implementing

1. Start with `app/config.py` (constants, paths, label names)
2. Then `app/model.py` (DistilBERTForMoodAndEmotions)
3. Then `app/dataset.py` (CSV loading + tokenization)
4. Then `app/trainer.py` (training loop with combined loss)
5. Then `app/evaluate.py` (metrics computation)
6. Then `app/inference.py` (prediction from raw text)
7. Then the three entry-point scripts in root
8. Finally `export_onnx.py`

## Testing

No formal test framework set up yet. Run scripts manually to verify:
- `.venv/bin/python3 train.py` should complete without error and produce `models/` output
- `.venv/bin/python3 evaluate.py` should print metrics to stdout
- `.venv/bin/python3 chat.py` should accept input and print predictions

## Prohibitions

- Do NOT add comments to code
- Do NOT commit to git unless explicitly asked
- Do NOT create documentation files (`.md`) unless explicitly asked
- Do NOT add emojis to files
