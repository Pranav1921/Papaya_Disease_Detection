# 🍃 Papaya Disease Detection System

An AI-powered system to detect diseases in papaya leaves using a unique 3-stage validation pipeline. The project consists of a **FastAPI Backend** and a **Flutter Mobile App**.

## 🚀 Key Features
- **3-Stage AI Verification:** 
    1. **Stage 1 (Color):** Heuristic green-ratio check to ensure the image contains a plant.
    2. **Stage 2 (Shape):** AI-powered shape verification (specifically looking for the 7-lobe palmate pattern).
    3. **Stage 3 (Disease):** TensorFlow model classification (Healthy, Leaf Curl, Powdery Mildew, Ringspot).
- **Expert Override:** Manual confirmation dialog if the AI is unsure (40%-60% confidence).
- **Stricter Rejection:** Automatically rejects "imposter" leaves (Mango, Banana, etc.) using ImageNet diagnostics.
- **Multi-lingual Support:** Kannada, Hindi, and English.

---

## 🛠️ Setup Instructions

### 1. Backend (FastAPI)
**Prerequisites:** Python 3.10+ installed.

```powershell
# Navigate to backend folder
cd papaya_disease_system

# Create and activate virtual environment
python -m venv .venv
.\.venv\Scripts\Activate.ps1

# Install dependencies
pip install -r requirements.txt

# Run the server
python app/api_server.py
```
*The server will run at `http://0.0.0.0:8001`*

### 2. Mobile App (Flutter)
**Prerequisites:** Flutter SDK and Android Studio installed.

```powershell
# Navigate to flutter folder
cd papaya_flutter_app

# Fetch dependencies
flutter pub get

# Connect your phone via USB and run
flutter run
```

---

## ☁️ Deployment Instructions (Hugging Face - FREE)

I have included a `Dockerfile` to make hosting the backend easy and free on Hugging Face Spaces.

1. Create a new **Space** on [Hugging Face](https://huggingface.co/new-space).
2. Select **Docker** as the SDK.
3. Choose the **Blank** template.
4. Go to the "Settings" tab of your Space and connect your **GitHub Repository**.
5. The backend will automatically build and provide you with a public URL (e.g., `https://username-space.hf.space`).

**Note:** Once deployed, update the `baseUrl` in `lib/services/api_backend_service.dart` to your new public URL.

---

## 👨‍💻 Development & Retraining

To improve the model's ability to reject non-papaya leaves:
1. Add images of other leaves to `papaya_disease_system/data/raw/background`.
2. Run the training script:
   ```powershell
   python papaya_disease_system/src/train.py
   ```

---

## 📄 Repository Structure
- `/papaya_disease_system`: Python FastAPI backend, ML models, and training scripts.
- `/papaya_flutter_app`: Flutter mobile application source code.
- `Dockerfile`: Configuration for cloud hosting.
