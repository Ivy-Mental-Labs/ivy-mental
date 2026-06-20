# Ivy Mental

*AI for Good Hackathon 2026, Team Ivy Labs*

**Ivy Mental** is a cross-platform mobile app for determining the user's mood and emotions
from spoken diary entries, powered by on-device machine learning models.

## Structure

| Folder         | Description                                                |
|----------------|------------------------------------------------------------|
| `app/`         | Flutter cross-platform mobile app                          |
| `ml_trainer/`  | Code for training a DistilBERT model (mood + 8 emotions)  |

## Quick Start

### 1. Train the model

```bash
cd ml_trainer
uv run train.py
```

### 2. Export to ONNX

```bash
uv run export_onnx.py
```

This produces `ml_trainer/models/model.onnx`.

### 3. Copy model assets to the app

```bash
cd ..
cp ml_trainer/models/model.onnx app/assets/ml/
```

### 4. Build & run the app

```bash
cd app
flutter pub get
flutter run
```

For a release build:

```bash
flutter build apk
flutter build ios
flutter build macos
flutter build windows
```
