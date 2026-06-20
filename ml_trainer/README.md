# ML Trainer — Ivy Mental

Trains a DistilBERT-based model that predicts **mood** (regression, -1 to 1) and **emotions** (multi-label, 0-1) from diary entry text.

## Quick start

```bash
uv sync                # install dependencies
uv run train.py        # train model on data/sample.csv
uv run evaluate.py     # evaluate on data/sample_eval.csv
uv run chat.py         # interactive CLI inference
uv run export_onnx.py  # export the model (see below)
```

## Model architecture

```
Input text → DistilBERT → [CLS] embedding
                                ↓
                       ┌────────────────┐
                       │ Shared encoder │
                       └────────────────┘
                              ↓
                 ┌────────────┴────────────┐
                 ↓                         ↓
        ┌──────────────────┐     ┌──────────────────┐
        │ Mood head (1)    │     │ Emotion head (8) │
        │ Linear → tanh    │     │ Linear → sigmoid │
        │ [-1, 1]          │     │ [0, 1] each      │
        └──────────────────┘     └──────────────────┘
```

Loss = `MSE(mood) + BCE(emotions)` (multi-task).

## Mobile deployment (Android / Flutter)

After training, export the model to ONNX format for use with ONNX Runtime on Android.

```bash
uv run export_onnx.py     # produces models/model.onnx + models/model.onnx.data
```

Copy both `model.onnx` and `model.onnx.data` into your Flutter app's assets and load them with the `onnxruntime` Flutter package:

```dart
// Example Dart/Flutter snippet
import 'package:onnxruntime/onnxruntime.dart';

final ort = OrtInference();
final session = await ort.loadModel('assets/model.onnx');

// Tokenize input text (use a portable tokenizer in Dart or pre-tokenize in Python)
// Input shape: [1, 128] for input_ids and attention_mask
// Outputs: mood (float) + emotions (8 floats)

final inputs = {
  'input_ids': OrtTensor.int64List(inputIds, [1, 128]),
  'attention_mask': OrtTensor.int64List(mask, [1, 128]),
};
final outputs = session.run(inputs);
final mood = outputs['mood'].data[0];         // float, range [-1, 1]
final emotions = outputs['emotions'].data;     // List of 8 floats
```

- Input names: `input_ids`, `attention_mask` (int64, shape `[batch, 128]`)
- Output names: `mood` (float32, shape `[batch, 1]`), `emotions` (float32, shape `[batch, 8]`)
- Raw emotion output: logits — apply `sigmoid` in your app to get [0, 1] probabilities

## Dataset

| Column | Type | Range | Description |
|--------|------|-------|-------------|
| `diary_entry` | string | — | Diary entry text |
| `mood` | float | -1 to 1 | Mood score (negative → positive) |
| `happy` | int | 0/1 | Emotion: happy |
| `sad` | int | 0/1 | Emotion: sad |
| `satisfied` | int | 0/1 | Emotion: satisfied |
| `proud` | int | 0/1 | Emotion: proud |
| `anxious` | int | 0/1 | Emotion: anxious |
| `angry` | int | 0/1 | Emotion: angry |
| `afraid` | int | 0/1 | Emotion: afraid |
| `jealous` | int | 0/1 | Emotion: jealous |

## Dependencies

Managed via `uv`. Key libraries: PyTorch, Transformers, Datasets, Optimum, ONNX Runtime, scikit-learn, pandas.
