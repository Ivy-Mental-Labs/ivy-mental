# IvyMental 🌿

*AI for Good Hackathon 2026 — Team Ivy Labs*

**IvyMental** is a privacy-first, cross-platform mobile diary app that helps users monitor their mental health. By analyzing spoken diary entries, it determines the user's mood and emotional patterns using optimized, on-device machine learning models. 

<p align="center">
  <img src="app/assets/playstore/Android%20Large%20-1Playstore_1.png" width="30%" alt="IvyMental Recording Screen" />
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="app/assets/playstore/Android%20Large%20-2Playstore_1.png" width="30%" alt="IvyMental History Screen" />
  &nbsp;&nbsp;&nbsp;&nbsp;
  <img src="app/assets/playstore/Android%20Large%20-3Playstore_1.png" width="30%" alt="IvyMental Trends Screen" />
</p>

## Key Features

- **On-Device Machine Learning (ONNX)**: Classifies mood and 8 distinct emotional categories (Calm, Energy, Stress, etc.) directly on your device using a DistilBERT model.
- **Offline Voice Check-ins**: Powered by local Whisper STT (Speech-to-Text) for instant transcription of voice diaries.
- **Privacy First**: All audio processing, transcriptions, and analyses are performed entirely on-device. No cloud APIs, no databases tracking your thoughts, and zero network calls for your personal data.
- **Smart Notification Reminders**: Fully configurable daily reminder times and score threshold reminders that automatically check if your rolling weekly average score falls below a threshold to suggest seeking support.

---

## Structure

| Folder | Description |
| :--- | :--- |
| [`app/`](file:///app) | Flutter cross-platform mobile app codebase. |
| [`ml_trainer/`](file:///ml_trainer) | Python script suite to train and export the DistilBERT model (mood + 8 emotions). |

---

## Getting Started

### 1. Train the ML Model
Navigate to the trainer folder to train the model locally using `uv` (or your preferred Python package manager):
```bash
cd ml_trainer
uv run train.py
```

### 2. Export to ONNX Format
Convert the trained DistilBERT weights into an ONNX model optimized for mobile devices:
```bash
uv run export_onnx.py
```
This output saves the compiled model at `ml_trainer/models/model.onnx`.

### 3. Package Model Assets inside Flutter
Copy the ONNX model and the vocabulary token text file into the Flutter asset registry:
```bash
cp ml_trainer/models/model.onnx ../app/assets/ml/
```

### 4. Build and Run the App
Navigate into the `app` directory, install packages, and launch:
```bash
cd ../app
flutter pub get
flutter run
```

To compile production-ready release builds:
```bash
flutter build appbundle    # Android (Google Play)
flutter build ipa          # iOS (App Store)
```

