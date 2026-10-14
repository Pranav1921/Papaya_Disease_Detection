# 🌿 Papaya Disease Detection System

A complete end-to-end precision agriculture solution integrating Deep Learning, Explainable AI (Grad-CAM), a FastAPI backend, a Streamlit dashboard, and a cross-platform Flutter mobile application to diagnose papaya leaf diseases in real-time.

---

## 📌 Overview

Papaya (*Carica papaya*) is a vital fruit crop prone to devastating foliar diseases that significantly reduce agricultural yield. This project provides farmers and agricultural researchers with an accessible, automated diagnostic system using computer vision.

### Key Capabilities
- **Multi-Class Disease Classification:** Detects and distinguishes between:
  - **Papaya Ringspot Virus (PRSV)**
  - **Powdery Mildew**
  - **Leaf Curl Disease**
  - **Healthy Leaves**
  - **Background / Non-Leaf Rejection**
- **Explainable AI (XAI):** Incorporates Grad-CAM (Gradient-weighted Class Activation Mapping) to visually highlight infected leaf regions.
- **Intelligent Preprocessing:** Leaf validation and background segmentation (via Rembg) to filter non-target images before inference.
- **Actionable Advisory:** Tailored organic and chemical treatment recommendations with weather-aware advisories.
- **Cross-Platform Mobile App:** Flutter client featuring live camera scanning, multi-language/TTS audio guidance, and history tracking.

---

## 🏗️ Project Architecture

```
Papaya-Disease-Detection/
├── papaya_disease_system/         # Python Deep Learning Backend & Services
│   ├── app/
│   │   ├── api_server.py          # FastAPI REST API server
│   │   └── streamlit_app.py       # Streamlit interactive web dashboard
│   ├── models/
│   │   ├── papaya_model.keras     # Trained MobileNetV2 Keras model
│   │   └── papaya_model.tflite    # Quantized TensorFlow Lite edge model
│   ├── src/                       # Training, preprocessing & XAI pipeline
│   │   ├── gradcam.py             # Grad-CAM heatmap generator
│   │   ├── preprocess.py          # Image augmentation and preprocessing
│   │   ├── recommend.py           # Disease treatment recommendations
│   │   ├── train.py               # Model training pipeline
│   │   └── weather.py             # Weather API integration
│   ├── data/                      # Dataset (raw & sample images)
│   └── requirements.txt           # Python dependencies
│
├── papaya_flutter_app/            # Flutter Mobile Application
│   ├── lib/
│   │   ├── models/                # App data models
│   │   ├── screens/               # UI screens (Home, Camera, Results, History)
│   │   ├── services/              # API & audio TTS services
│   │   └── main.dart              # Application entry point
│   ├── pubspec.yaml               # Flutter package configuration
│   └── assets/                    # Static assets & icons
│
├── project_report/                # Academic Project Report
│   ├── main.tex                   # Complete LaTeX source
│   └── images/                    # Report figures & diagrams
│
└── Papaya_Disease_Detection_Conference_Paper.docx # Conference Paper Draft
```

---

## 🚀 Getting Started

### 1. Backend Server Setup (FastAPI & Streamlit)

Ensure you have Python 3.10+ installed.

```bash
# Navigate to the backend directory
cd papaya_disease_system

# Create and activate a virtual environment
python -m venv venv
# Windows:
.\venv\Scripts\activate
# Linux/macOS:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run FastAPI API server
uvicorn app.api_server:app --host 0.0.0.0 --port 8000 --reload

# Alternatively, run the Streamlit Web Dashboard:
streamlit run app.streamlit_app.py
```

### 2. Flutter Mobile Application

Ensure you have Flutter SDK installed (`flutter doctor`).

```bash
# Navigate to the Flutter project
cd papaya_flutter_app

# Fetch packages
flutter pub get

# Run on a connected Android/iOS device or emulator
flutter run
```

---

## ☁️ Cloud Deployment (Hugging Face Spaces - Free)

A `Dockerfile` is included for zero-config hosting of the FastAPI inference backend:

1. Create a new Space on [Hugging Face Spaces](https://huggingface.co/new-space).
2. Choose **Docker** as the SDK and select **Blank**.
3. Under Space settings, link your GitHub repository.
4. Once deployed, update `baseUrl` in [`papaya_flutter_app/lib/services/api_backend_service.dart`](papaya_flutter_app/lib/services/api_backend_service.dart) to point to your live URL.

---

## 📊 Dataset & Model Details

- **Base Architecture:** Transfer learning using MobileNetV2 with custom dense classification layers.
- **Edge Deployment:** Exported to quantized TensorFlow Lite (`.tflite`) for efficient on-device or edge deployment.
- **Validation:** Pre-inference check verifying leaf presence before executing model inference.

---

## 📄 Documentation & Research

- Complete technical documentation and methodology can be found in [`project_report/main.tex`](project_report/main.tex).
- Research findings and experimental results are summarized in `Papaya_Disease_Detection_Conference_Paper.docx`.
