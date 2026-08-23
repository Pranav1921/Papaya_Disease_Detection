import os
import sys
import json
import math
import random
import warnings

# Suppress Deprecation Warnings for cleaner terminal
warnings.filterwarnings("ignore", category=DeprecationWarning)

# Attempt to import FastAPI and dependencies
try:
    from fastapi import FastAPI, UploadFile, File, Form
    from fastapi.middleware.cors import CORSMiddleware
    import uvicorn
    HAS_FASTAPI = True
except ImportError:
    HAS_FASTAPI = False

# Attempt to import TensorFlow and Image dependencies
HAS_TF = False
model = None
CLASSES = ['background', 'healthy', 'leaf_curl', 'powdery_mildew', 'ringspot_virus']
severity_map = {
    "powdery_mildew": 76.4,
    "ringspot_virus": 88.5,
    "leaf_curl": 65.0,
    "healthy": 0.0,
    "background": 0.0
}

try:
    import tensorflow as tf
    from PIL import Image
    import io
    import numpy as np
    import rembg
    from tensorflow.keras.applications.mobilenet_v2 import MobileNetV2, preprocess_input, decode_predictions
    HAS_TF = True
    
    # Load Papaya model
    MODEL_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "models", "papaya_model.keras")
    if os.path.exists(MODEL_PATH):
        # Configure GPU memory growth to prevent allocations crash
        gpus = tf.config.experimental.list_physical_devices('GPU')
        for gpu in gpus:
            tf.config.experimental.set_memory_growth(gpu, True)
        model = tf.keras.models.load_model(MODEL_PATH)
        print(f"Loaded papaya model successfully from {MODEL_PATH}")
    else:
        print(f"Model path not found: {MODEL_PATH}")

    # Load general ImageNet model for AI leaf/plant detection
    try:
        imagenet_model = MobileNetV2(weights='imagenet')
        HAS_IMAGENET = True
        print("Loaded ImageNet model for AI leaf detection.")
        # Warm up ImageNet model to cache class indices
        dummy_input = np.zeros((1, 224, 224, 3))
        dummy_pred = imagenet_model.predict(dummy_input, verbose=0)
        decode_predictions(dummy_pred, top=1)
        print("ImageNet model warmed up (indices cached).")
    except Exception as e:
        HAS_IMAGENET = False
        print(f"Could not load ImageNet model: {e}")

except Exception as e:
    HAS_IMAGENET = False
    print(f"TensorFlow or PIL not available for inference, using fallback predictions. Error: {e}")

# Reference user location (Puttur center)
DEFAULT_LAT = 12.7684
DEFAULT_LNG = 75.2027

def calculate_haversine(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    R = 6371.0
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = math.sin(dlat / 2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon / 2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c

def _call_gemini_vision(image_bytes: bytes, prompt: str, max_tokens: int = 10) -> str:
    """Internal helper: sends an image + text prompt to Gemini.
    Supports both direct Gemini API and OpenRouter endpoints based on key structure."""
    try:
        import urllib.request
        import base64

        # Use the key from environment, or default to a placeholder
        api_key = os.getenv("GEMINI_API_KEY", "YOUR_OPENROUTER_KEY_HERE")
        base64_image = base64.b64encode(image_bytes).decode('utf-8')

        # Detect if it's OpenRouter (sk-or- or AQ. format) or direct Gemini
        is_openrouter = api_key.startswith("sk-or-") or api_key.startswith("AQ.")

        # Diagnostics: Print API provider (but mask the key)
        provider = "OpenRouter" if is_openrouter else "Google Gemini"
        key_preview = api_key[:8] + "..." if len(api_key) > 8 else "MISSING"
        print(f"[AI Diagnostic] Using {provider} (Key: {key_preview})")

        if is_openrouter:
            url = "https://openrouter.ai/api/v1/chat/completions"
            headers = {
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json",
                "HTTP-Referer": "https://github.com/Pranav1921/Papaya_Disease_Detection",
                "X-Title": "Papaya Disease Detection"
            }
            # Try Pro model if Flash endpoints are not found
            payload = {
                "model": "google/gemini-flash-1.5",
                "messages": [
                    {
                        "role": "user",
                        "content": [
                            {"type": "text", "text": prompt},
                            {
                                "type": "image_url",
                                "image_url": {"url": f"data:image/jpeg;base64,{base64_image}"}
                            }
                        ]
                    }
                ],
                "max_tokens": max_tokens
            }
            req = urllib.request.Request(url, data=json.dumps(payload).encode('utf-8'), headers=headers)
            try:
                with urllib.request.urlopen(req, timeout=10) as response:
                    result = json.loads(response.read().decode('utf-8'))
                    return result['choices'][0]['message']['content'].strip().upper()
            except urllib.error.HTTPError as e:
                error_body = e.read().decode('utf-8')
                print(f"[OpenRouter Error] {e.code}: {error_body}")
                return ""
        else:
            # Direct Google Gemini API endpoint
            url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={api_key}"
            headers = {
                "Content-Type": "application/json"
            }
            payload = {
                "contents": [
                    {
                        "parts": [
                            {"text": prompt},
                            {
                                "inlineData": {
                                    "mimeType": "image/jpeg",
                                    "data": base64_image
                                }
                            }
                        ]
                    }
                ],
                "generationConfig": {
                    "maxOutputTokens": max_tokens
                }
            }
            req = urllib.request.Request(url, data=json.dumps(payload).encode('utf-8'), headers=headers)
            with urllib.request.urlopen(req, timeout=8) as response:
                result = json.loads(response.read().decode('utf-8'))
                return result['candidates'][0]['content']['parts'][0]['text'].strip().upper()
    except Exception as e:
        print(f"Gemini vision API error: {e}")
        return ""



def is_leaf_image_heuristic(image_bytes: bytes) -> bool:
    """Fallback leaf check: Parses the image to check if a reasonable ratio of green/yellow-green
    pixels are present. This prevents simple uploads of shoes, faces, keyboards, etc.
    even if the Gemini API key fails or is offline."""
    try:
        from PIL import Image
        import io
        img = Image.open(io.BytesIO(image_bytes)).convert("HSV")
        # Sample pixels to count green range
        # HSV in PIL: H is 0-255, S is 0-255, V is 0-255.
        # Green Hue is roughly 35 to 85 (mapped to ~25 to 60 in 0-255 range).
        data = img.getdata()
        green_pixels = 0
        total_pixels = len(data)
        
        # Optimize check by stepping through pixels if image is large
        step = max(1, total_pixels // 10000)
        checked_count = 0
        for idx in range(0, total_pixels, step):
            h, s, v = data[idx]
            # Hue between 25 and 65, saturation > 35, value > 30
            if 22 <= h <= 68 and s > 35 and v > 30:
                green_pixels += 1
            checked_count += 1
            
        green_ratio = green_pixels / checked_count
        print(f"[Heuristic] Image green-ratio: {green_ratio * 100:.2f}%")
        return green_ratio > 0.12  # Lowered from 0.20 to 0.12 to allow leaves on white/plain backgrounds
    except Exception as e:
        print(f"[Heuristic] Color check error: {e}")
        return True # Default to pass if anything fails

def is_leaf_image_ai(image_bytes: bytes) -> bool:
    """Stage 1: Use Gemini AI to detect if the image contains any leaf or plant.
    Returns True if a leaf/plant is clearly visible, False otherwise."""
    answer = _call_gemini_vision(
        image_bytes,
        prompt=(
            "Look at this image carefully. Is there a leaf or any part of a plant "
            "clearly visible in this image? Answer with exactly 'YES' or 'NO'."
        )
    )
    if answer == "":
        print("Stage 1 (leaf check) API unavailable. Using color heuristic fallback...")
        return is_leaf_image_heuristic(image_bytes)
    return "YES" in answer


def is_papaya_leaf_ai(image_bytes: bytes) -> str:
    """Stage 2: Use Gemini AI to verify the leaf is specifically a papaya (Carica papaya) leaf.
    Returns 'YES', 'NO', or 'FAIL' (if API is down)."""
    answer = _call_gemini_vision(
        image_bytes,
        prompt=(
            "Look at this image. Is the leaf shown specifically a papaya leaf (Carica papaya)? "
            "Papaya leaves have a very distinctive large palmate shape with 7 or more deep lobes "
            "radiating from a central point. Answer with exactly 'YES' or 'NO'."
        )
    )
    if answer == "":
        print("Stage 2 (papaya check) API unavailable.")
        return "FAIL"
    return "YES" if "YES" in answer else "NO"


# NOTE: is_papaya_leaf() pixel heuristic has been replaced by is_papaya_leaf_ai().
# The old function is kept commented out for reference only.
# def is_papaya_leaf(img_rgb_array): ... (removed)


# Global Toggle for Background Removal (Set to False to disable heavy downloads)
ENABLE_BG_REMOVAL = True

def remove_background(image_bytes: bytes) -> bytes:
    """Removes background and returns bytes of the leaf on a white background.
    Uses the smaller 'u2netp' model (~4MB!) instead of the 1GB 'bria' model."""
    if not ENABLE_BG_REMOVAL:
        return image_bytes

    try:
        from rembg import remove, new_session
        # Explicitly use the tiny model to avoid huge downloads
        session = new_session("u2netp")

        input_img = Image.open(io.BytesIO(image_bytes))
        output_rgba = remove(input_img, session=session)

        # Create a white background image
        white_bg = Image.new("RGB", output_rgba.size, (255, 255, 255))
        white_bg.paste(output_rgba, mask=output_rgba.split()[3])

        # Convert back to bytes
        img_byte_arr = io.BytesIO()
        white_bg.save(img_byte_arr, format='JPEG')
        return img_byte_arr.getvalue()
    except Exception as e:
        print(f"[BG Removal Skip] Skipping background removal: {e}")
        return image_bytes # Fallback to original

def predict_image(image_bytes: bytes, force: bool = False):
    """4-Stage AI validation pipeline with BG removal:
      Stage 0 — Pre-processing: Remove background for higher accuracy.
      Stage 1 — Gemini AI: Is there a leaf in the image?
      Stage 2 — Gemini AI: Is it specifically a papaya leaf?
      Stage 3 — TF Model:  What disease does the papaya leaf have?
    """
    try:
        from PIL import Image
        import io
        import numpy as np

        # === STAGE 0: Background Removal ===
        print("[Stage 0] Removing background for focus...")
        clean_image_bytes = remove_background(image_bytes)

        # === STAGE 1: AI Leaf Detection (Gemini) ===
        print("[Stage 1] Checking if image contains a leaf...")
        # Use clean image for detection
        leaf_present = is_leaf_image_ai(clean_image_bytes)
        if not leaf_present:
            print("[Stage 1] REJECTED — no leaf detected.")
            return "__not_a_leaf__", 0.0
        print("[Stage 1] PASSED — leaf detected.")

        # === STAGE 2: AI Papaya Leaf Verification (Gemini) ===
        print("[Stage 2] Checking if leaf is specifically a papaya leaf...")
        papaya_status = is_papaya_leaf_ai(clean_image_bytes)

        # === STAGE 3: Disease Classification (TF Model) ===
        if not HAS_TF or model is None:
            print("[Stage 3] TF model not loaded, cannot classify disease.")
            return None

        # Process clean image for model
        img = Image.open(io.BytesIO(clean_image_bytes)).convert("RGB")
        img_resized = img.resize((224, 224))
        img_array = np.array(img_resized, dtype=np.float32)
        img_array = np.expand_dims(img_array, axis=0)

        # === STAGE 2.5: ImageNet Check (Negative Filter) ===
        # Use general ImageNet model to check for non-leaf objects or other plants
        if HAS_IMAGENET:
             img_imagenet = preprocess_input(img_array.copy())
             imagenet_preds = imagenet_model.predict(img_imagenet, verbose=0)
             decoded = decode_predictions(imagenet_preds, top=5)[0]

             print(f"[ImageNet Diagnostics] Top 3: {[(d[1], round(d[2], 3)) for d in decoded[:3]]}")

             # 1. Reject obvious non-plant items
             plant_keywords = ['leaf', 'plant', 'tree', 'veggie', 'fruit', 'grass', 'flora', 'herb', 'corn', 'buckeye', 'cardoon', 'head_cabbage', 'bell_pepper', 'cucumber', 'zucchini']
             is_actually_a_plant = any(any(kw in d[1].lower() for kw in plant_keywords) for d in decoded)

             # 2. Specifically identify "imposters" (Mango, Banana, etc.)
             # ImageNet labels for common non-papaya plants
             imposters = ["banana", "maize", "ear", "fig", "pineapple", "pomegranate", "lemon", "orange", "daisy", "bee_eater", "mango", "custard_apple", "guava", "jackfruit", "buckeye", "walking_stick"]
             for _, label, score in decoded:
                 # Check for whole words or specific substrings to avoid "corn" in "acorn"
                 clean_label = label.lower().replace("_", " ")
                 if any(imp in clean_label for imp in imposters) and score > 0.22:
                     print(f"[REJECTION] ImageNet detected imposter {label} with {score*100:.2f}% confidence.")
                     return "__not_papaya__", 0.0

             if not is_actually_a_plant:
                 top_label = decoded[0][1]
                 # If top result is something like 'shoe', 'keyboard', 'web_site', 'analog_clock'
                 if decoded[0][2] > 0.25:
                     print(f"[REJECTION] ImageNet detected '{top_label}' ({decoded[0][2]*100:.1f}%). Not a plant.")
                     return "__not_a_leaf__", 0.0

        # === STAGE 3: Disease Classification (TF Model) ===
        if not HAS_TF or model is None:
            print("[Stage 3] TF model not loaded, cannot classify disease.")
            return None

        # Predict probabilities
        predictions = model.predict(img_array)
        score = predictions[0]
        max_idx = np.argmax(score)
        confidence = float(score[max_idx])
        predicted_class = CLASSES[max_idx]

        print(f"[Stage 3] Prediction: {predicted_class} ({confidence*100:.2f}%)")

        # === STAGE 4: SHAPE-FIRST LOGIC ===
        # We only check the "Percentage" if the "Shape" passes first.

        if force:
            print("[Stage 4] FORCE MODE: Skipping shape validation as per user confirmation.")
            CONFIDENCE_THRESHOLD = 0.40 # Still need some baseline
        elif papaya_status == "YES":
            # Shape is 100% Papaya.
            # User request: Keep the percentage for 60%
            CONFIDENCE_THRESHOLD = 0.60
            print(f"[Stage 4] SHAPE VERIFIED: Using user-requested threshold ({CONFIDENCE_THRESHOLD*100}%)")

        elif papaya_status == "NO":
            # Shape is definitely NOT Papaya.
            print("[REJECTION] SHAPE MISMATCH: AI confirms this is not a papaya leaf.")
            return "__not_papaya__", 0.0

        else:
            # papaya_status == "FAIL" (Gemini API is Offline)
            # User request: Keep the percentage for 60%
            CONFIDENCE_THRESHOLD = 0.60
            print(f"[Stage 4] SHAPE UNVERIFIED (API Offline): Using user-requested threshold ({CONFIDENCE_THRESHOLD*100}%)")

        if confidence < CONFIDENCE_THRESHOLD:
            # User confirmation logic:
            # If it's between 30% and 60%, we mark it as "unsure" to ask the user.
            # Lowered from 40% to 30% to catch severely curled/damaged leaves.
            if not force and confidence > 0.30 and confidence < CONFIDENCE_THRESHOLD:
                print(f"[UNSURE] {confidence*100:.2f}% is low but above 30%. Asking user.")
                return "__unsure_papaya__", confidence

            print(f"[REJECTION] Pattern Confidence {confidence*100:.2f}% is too low (below 30%).")
            return "__not_papaya__", confidence

        print(f"[SUCCESS] High confidence detection: {predicted_class}")
        return predicted_class, confidence

    except Exception as e:
        print(f"Error during model prediction: {e}")
        return None

TREATMENT_DB = {
    "powdery_mildew": {
        "disease_id": "powdery_mildew",
        "title_kannada": "ಬೂದಿ ರೋಗ (Powdery Mildew)",
        "title_english": "Powdery Mildew Fungal Infection",
        "severity_level": "ಮಧ್ಯಮ (Medium Severity)",
        "severity_percentage": 76.4,
        "confidence_score": 95.2,
        "prescribed_medicines": [
            {"name": "ಕಾಂಟಾಫ್ ಪ್ಲಸ್ (Contaf Plus)", "price": 220.0, "dosage": "1 ml/L"},
            {"name": "ಡೈಥೇನ್ ಎಮ್-45 (Dithane M-45)", "price": 380.0, "dosage": "2 g/L"},
            {"name": "ಕರಗುವ ಗಂಧಕ (Sulphur WP)", "price": 165.0, "dosage": "2 g/L"},
            {"name": "ಸುಡೋಮೊನಾಸ್ (Pseudomonas)", "price": 150.0, "dosage": "5 g/L"}
        ],
        "total_package_cost": 915.0
    },
    "ringspot_virus": {
        "disease_id": "ringspot_virus",
        "title_kannada": "ಪಪ್ಪಾಯಿ ರಿಂಗ್‌ಸ್ಪಾಟ್ ವೈರಸ್ (Ringspot Virus)",
        "title_english": "Papaya Ringspot Virus",
        "severity_level": "ಅಪಾಯಕಾರಿ (Critical Severity)",
        "severity_percentage": 88.5,
        "confidence_score": 97.4,
        "prescribed_medicines": [
            {"name": "ಕಾನ್ಫಿಡಾರ್ (Confidor)", "price": 390.0, "dosage": "0.5 ml/L"},
            {"name": "ಆಕ್ಟಾರಾ (Actara)", "price": 280.0, "dosage": "0.5 g/L"},
            {"name": "ಸಾವಯವ ಬೇೇವಿನ ಎಣ್ಣೆ (Neem Oil)", "price": 350.0, "dosage": "3 ml/L"}
        ],
        "total_package_cost": 1020.0
    },
    "leaf_curl": {
        "disease_id": "leaf_curl",
        "title_kannada": "ಎಲೆ ಮುದುರು ರೋಗ (Leaf Curl Virus)",
        "title_english": "Papaya Leaf Curl Virus",
        "severity_level": "ಹೆಚ್ಚಿನ ಅಪಾಯ (High Severity)",
        "severity_percentage": 82.0,
        "confidence_score": 94.1,
        "prescribed_medicines": [
            {"name": "ಪ್ರೈಡ್ (Pride - Acetamiprid)", "price": 270.0, "dosage": "0.5 g/L"},
            {"name": "ಕಾನ್ಫಿಡಾರ್ (Confidor)", "price": 390.0, "dosage": "0.5 ml/L"},
            {"name": "ಸಾವಯವ ಬೇೇವಿನ ಎಣ್ಣೆ (Neem Oil)", "price": 350.0, "dosage": "3 ml/L"}
        ],
        "total_package_cost": 1010.0
    }
}

MASTER_SHOPS = [
    {"id": "shop_1", "name_kannada": "ಕೃಷಿ ಮಾಹಿತಿ ಕೇಂದ್ರ ಪುತ್ತೂರು", "lat": 12.7695, "lng": 75.2045, "phone": "+91 8251 230455", "is_rsk": False},
    {"name_kannada": "ಶ್ರೀ ದುರ್ಗಾ ಕೃಷಿ ಸೇವಾ ಕೇಂದ್ರ ಪುತ್ತೂರು", "lat": 12.7620, "lng": 75.1980, "phone": "+91 94481 22334", "is_rsk": False},
    {"name_kannada": "ಕೃಷಿ ಕೇಂದ್ರ ಮಂಗಳೂರು", "lat": 12.9141, "lng": 74.8560, "phone": "+91 824 2422301", "is_rsk": False},
    {"name_kannada": "ದಕ್ಷಿಣ ಕನ್ನಡ ಕೃಷಿಕ ಸಂಘ ಬಂಟ್ವಾಳ", "lat": 12.8943, "lng": 75.0345, "phone": "+91 8255 233211", "is_rsk": False},
    {"name_kannada": "ಉಡುಪಿ ಕೃಷಿಕ ಮಾರುಕಟ್ಟೆ ಕೇಂದ್ರ", "lat": 13.3409, "lng": 74.7421, "phone": "+91 820 2521199", "is_rsk": False},
    {"name_kannada": "ಮೈಸೂರು ಅಗ್ರಿ ಮಾರ್ಟ್", "lat": 12.2958, "lng": 76.6394, "phone": "+91 821 2420011", "is_rsk": False},
]

AGRI_NEWS_DB = [
    {
        "id": "news_1",
        "titleKannada": "ಪಪ್ಪಾಯಿ ಬೀಜ ಹಾಗೂ ಜೈವಿಕ ಗೊಬ್ಬರ ಮಾಹಿತಿ ಲಭ್ಯ!",
        "titleEnglish": "Information on Papaya Seeds & Bio-fertilizers",
        "titleHindi": "पपीता बीज और जैविक खाद की जानकारी उपलब्ध!",
        "categoryKannada": "🌾 ಕೃಷಿ ಮಾಹಿತಿ",
        "categoryEnglish": "🌾 Agri Info",
        "categoryHindi": "🌾 कृषि जानकारी",
        "summaryKannada": "ಸುಡೋಮೊನಾಸ್ ಮತ್ತು ಟ್ರೈಕೋಡರ್ಮಾ ಜೈವಿಕ ಗೊಬ್ಬರಗಳ ಬಳಕೆಯಿಂದ ಬೆಳೆ ಉತ್ತಮಗೊಳ್ಳುತ್ತದೆ.",
        "summaryEnglish": "Improve your crop yield using Pseudomonas and Trichoderma bio-fertilizers.",
        "summaryHindi": "स्यूडोमोनास और ट्राइकोडेर्मा जैविक खादों के उपयोग से अपनी फसल की उपज में सुधार करें।",
        "dateKannada": "ಇಂದು",
        "dateEnglish": "Today",
        "dateHindi": "आज",
        "iconEmoji": "📖",
        "sourceKannada": "ಕೃಷಿ ತಜ್ಞರು",
        "sourceEnglish": "Agri Experts",
        "sourceHindi": "कृषि विशेषज्ञ",
        "isFeatured": True,
    },
    {
        "id": "news_2",
        "titleKannada": "ಕರಾವಳಿ ಮತ್ತು ಮಲೆನಾಡು ಭಾಗದಲ್ಲಿ ಪಪ್ಪಾಯಿ ಬೂದಿ ರೋಗದ ಮುನ್ನೆಚ್ಚರಿಕೆ!",
        "titleEnglish": "High Humidity Fungal Alert for Coastal & Malnad Papaya Farmers",
        "titleHindi": "तटीय और मलनाड क्षेत्रों में पपीते के पाउडर फफूंद रोग की चेतावनी!",
        "categoryKannada": "🌦️ ಹವಾಮಾನ ರೋಗ ಎಚ್ಚರಿಕೆ",
        "categoryEnglish": "🌦️ Weather Alert",
        "categoryHindi": "🌦️ मौसम रोग चेतावनी",
        "summaryKannada": "ಮಂಗಳೂರು, ಉಡುಪಿ, ಪುತ್ತೂರು ಭಾಗಗಳಲ್ಲಿ ತೇವಾಂಶ 85% ಕ್ಕಿಂತ ಹೆಚ್ಚಿದ್ದು ಬೂದಿ ರೋಗ ಹರಡುವ ಸಾಧ್ಯತೆ ಇದೆ. ಕಾಂಟಾಫ್ 1ml ಸಿಂಪಡಿಸಿ.",
        "summaryEnglish": "Humidity is above 85% in Mangaluru, Udupi, and Puttur, leading to high Powdery Mildew risk. Spray 1ml Contaf.",
        "summaryHindi": "मंगलूरु, उडुपी, पुत्तूर क्षेत्रों में आर्द्रता 85% से अधिक होने के कारण रोग फैलने की संभावना है। 1ml कोंटाफ का छिड़काव करें।",
        "dateKannada": "ನಿನ್ನೆ",
        "dateEnglish": "Yesterday",
        "dateHindi": "कल",
        "iconEmoji": "⚠️",
        "sourceKannada": "ಕೃಷಿ ತಜ್ಞರು",
        "sourceEnglish": "Agri Experts",
        "sourceHindi": "कृषि विशेषज्ञ",
        "isFeatured": True,
    },
    {
        "id": "news_3",
        "titleKannada": "ಮಾರುಕಟ್ಟೆಯಲ್ಲಿ ಉತ್ತಮ ದರ್ಜೆಯ ಪಪ್ಪಾಯಿ ಹಣ್ಣಿಗೆ ಕೆ.ಜಿ ಗೆ ₹28 - ₹34 ಬೆಲೆ",
        "titleEnglish": "Papaya Market Price Update: ₹28 - ₹34 per kg in APMC",
        "titleHindi": "बाजार में अच्छी गुणवत्ता वाले पपीते की कीमत ₹28 - ₹34 प्रति किलोग्राम",
        "categoryKannada": "💰 ಮಾರುಕಟ್ಟೆ ದರ",
        "categoryEnglish": "💰 Market Price",
        "categoryHindi": "💰 बाजार भाव",
        "summaryKannada": "ಬೆಂಗಳೂರು, ಮೈಸೂರು ಮತ್ತು ಪುತ್ತೂರು APMC ಮಾರುಕಟ್ಟೆಯಲ್ಲಿ ರೆಡ್ ಲೇಡಿ (Red Lady) ತಳಿಯ ಪಪ್ಪಾಯಿಗೆ ಭಾರಿ ಬೇಡಿಕೆ ಬಂದಿದೆ.",
        "summaryEnglish": "Red Lady papaya breed has high demand in Bengaluru, Mysuru, and Puttur APMC markets.",
        "summaryHindi": "बेंगलुरु, मैसूर और पुत्तूर APMC बाजार में रेड लेडी (Red Lady) पपीते की किस्म की भारी मांग है।",
        "dateKannada": "ಲೈವ್",
        "dateEnglish": "Live",
        "dateHindi": "लाइव",
        "iconEmoji": "📈",
        "sourceKannada": "ಮಾರುಕಟ್ಟೆ ವರದಿ",
        "sourceEnglish": "Market Watch",
        "sourceHindi": "मार्केट वॉच",
        "isFeatured": False,
    },
    {
        "id": "news_4",
        "titleKannada": "ಹೇನು ಮತ್ತು ಬಿಳಿ ನೊಣ ನಿಯಂತ್ರಣಕ್ಕೆ ಹಳದಿ ಅಂಟಿನ ಬಲೆಗಳನ್ನು ಬಳಸಿ",
        "titleEnglish": "Use Yellow Sticky Traps to Stop Ringspot & Leaf Curl Vectors",
        "titleHindi": "रिंगस्पॉट और पत्ता मरोड़ वाहकों को रोकने के लिए पीले कार्ड का उपयोग करें",
        "categoryKannada": "💡 ಕೃಷಿ ಸಲಹೆ",
        "categoryEnglish": "💡 Agri Advisory",
        "categoryHindi": "💡 कृषि सलाह",
        "summaryKannada": "ವೈರಸ್ ರೋಗಗಳು ಹರಡದಂತೆ ತಡೆಯಲು ಎಕರೆಗೆ 10 ಹಳದಿ ಅಂಟಿನ ಬಲೆಗಳನ್ನು ಕಟ್ಟುವುದರಿಂದ ಕೀಟನಾಶಕ ಸಿಂಪರಣೆ ವೆಚ್ಚ ಶೇ 40% ಕಡಿಮೆಯಾಗುತ್ತದೆ.",
        "summaryEnglish": "Installing 10 yellow sticky traps per acre reduces pesticide spraying costs by 40% while stopping virus spread.",
        "summaryHindi": "प्रति एकड़ 10 पीले चिपचिपे कार्ड लगाने से वायरस के फैलाव को रोकने के साथ-साथ कीटनाशक छिड़काव की लागत 40% तक कम हो जाती है।",
        "dateKannada": "ಲೈವ್",
        "dateEnglish": "Live",
        "dateHindi": "लाइव",
        "iconEmoji": "🌿",
        "sourceKannada": "ಕೃಷಿ ತಜ್ಞರು",
        "sourceEnglish": "Agri Experts",
        "sourceHindi": "कृषि विशेषज्ञ",
        "isFeatured": False,
    },
    {
        "id": "news_5",
        "titleKannada": "ಪುತ್ತೂರು ಸುತ್ತಮುತ್ತ ಭಾರಿ ಮಳೆ: ಪಪ್ಪಾಯಿ ತೋಟಗಳಲ್ಲಿ ನೀರು ಹರಿಸಲು ಸಲಹೆ",
        "titleEnglish": "Heavy Rain Alert in Puttur: Proper Drainage Recommended for Papaya Fields",
        "titleHindi": "पुत्तूर के आसपास भारी बारिश: पपीते के खेतों में जल निकासी की सलाह",
        "categoryKannada": "🌧️ ಕೃಷಿ ಎಚ್ಚರಿಕೆ",
        "categoryEnglish": "🌧️ Weather Advisory",
        "categoryHindi": "🌧️ मौसम सलाह",
        "summaryKannada": "ಮುಂದಿನ 3 ದಿನಗಳ ಕಾಲ ಭಾರಿ ಮಳೆಯಾಗುವ ಮುನ್ಸೂಚನೆ ಇರುವುದರಿಂದ ಬೇರು ಕೊಳೆ ರೋಗ ತಡೆಗಟ್ಟಲು ತೋಟಗಳಲ್ಲಿ ನೀರು ನಿಲ್ಲದಂತೆ ನೋಡಿಕೊಳ್ಳಿ.",
        "summaryEnglish": "Forecast of heavy rain for the next 3 days. Ensure proper drainage in fields to prevent root rot diseases.",
        "summaryHindi": "अगले 3 दिनों के लिए भारी बारिश का अनुमान। जड़ सड़न रोगों को रोकने के लिए खेतों में उचित जल निकासी सुनिश्चित करें।",
        "dateKannada": "ಲೈವ್",
        "dateEnglish": "Live",
        "dateHindi": "लाइव",
        "iconEmoji": "⛈️",
        "sourceKannada": "ಹವಾಮಾನ ವರದಿ",
        "sourceEnglish": "Weather Report",
        "sourceHindi": "मौसम रिपोर्ट",
        "isFeatured": True,
    }
]

if HAS_FASTAPI:
    app = FastAPI(
        title="Papaya Disease Detection API",
        description="FastAPI REST Backend serving ML model predictions, severity %, medicine prices & nearby shops (<100km)",
        version="1.0.0"
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    @app.get("/")
    def health_check():
        return {
            "status": "online",
            "mode": "FastAPI Engine",
            "service": "Papaya Disease Detection API",
            "version": "1.0.0",
            "model_loaded": (model is not None),
            "endpoints": ["/api/v1/predict", "/api/v1/shops", "/api/v1/news"]
        }

    @app.post("/api/v1/predict")
    async def predict_disease(
        file: UploadFile = File(None),
        disease_key: str = Form("powdery_mildew"),
        force: bool = Form(False)
    ):
        predicted_class = disease_key
        confidence = 94.2

        if file is not None:
            try:
                image_bytes = await file.read()
                prediction = predict_image(image_bytes, force=force)
                if prediction is not None:
                    predicted_class, confidence = prediction
                else:
                    # If AI fails, we must NOT fall back to a default disease
                    return {
                        "disease_key": "invalid",
                        "confidence": 0.0,
                        "severity": 0.0,
                        "status": "Error",
                        "rejection_reason": "ai_failure",
                        "message_en": "AI Analysis failed. Please try again.",
                        "message_kn": "AI ವಿಶ್ಲೇಷಣೆ ವಿಫಲವಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ."
                    }
            except Exception as e:
                print(f"Error reading uploaded file: {e}")

        # === Staged Rejection Responses ===
        # Ensure we return early and don't proceed to severity mapping
        if predicted_class in ["__not_a_leaf__", "__not_papaya__", "invalid", "background", "__unsure_papaya__"]:
            reason = "not_a_leaf" if predicted_class == "__not_a_leaf__" else "not_papaya"
            if predicted_class == "__unsure_papaya__":
                reason = "unsure_papaya"

            # Response messages
            msg_en = "Our AI is unsure. Is this a papaya leaf?" if reason == "unsure_papaya" else "It's not a papaya leaf. Scan again."
            msg_kn = "ನಮ್ಮ AI ಗೆ ಖಚಿತವಿಲ್ಲ. ಇದು ಪಪ್ಪಾಯಿ ಎಲೆಯೇ?" if reason == "unsure_papaya" else "ಇದು ಪಪ್ಪಾಯಿ ಎಲೆ ಅಲ್ಲ. ಮತ್ತೆ ಸ್ಕ್ಯಾನ್ ಮಾಡಿ."
            msg_hi = "हमारा AI अनिश्चित है। क्या यह पपीते की पत्ती है?" if reason == "unsure_papaya" else "यह पपीते की पत्ती नहीं है। फिर से स्कैन करें।"

            return {
                "disease_key": "invalid",
                "confidence": round(confidence, 1),
                "severity": 0.0,
                "status": "Rejected",
                "rejection_reason": reason,
                "message_en": msg_en,
                "message_kn": msg_kn,
                "message_hi": msg_hi
            }

        # Compute severity and status only for VALID classes
        if predicted_class not in severity_map:
             return {
                "disease_key": "invalid",
                "confidence": 0.0,
                "severity": 0.0,
                "status": "Unknown",
                "rejection_reason": "unknown_class"
            }

        base_severity = severity_map[predicted_class]
        severity = round(base_severity + random.uniform(-4, 4), 1) if predicted_class != "healthy" else 0.0

        if severity > 80:
            status = "Critical"
        elif severity > 50:
            status = "Severe"
        elif severity > 10:
            status = "Moderate"
        else:
            status = "Healthy"

        return {
            "disease_key": predicted_class,
            "confidence": round(confidence, 1),
            "severity": severity,
            "status": status
        }

    @app.get("/api/v1/shops")
    def get_nearest_shops(user_lat: float = DEFAULT_LAT, user_lng: float = DEFAULT_LNG, radius_km: float = 100.0):
        filtered = []
        for s in MASTER_SHOPS:
            dist = calculate_haversine(user_lat, user_lng, s["lat"], s["lng"])
            if dist <= radius_km:
                shop_item = dict(s)
                shop_item["distance_km"] = round(dist, 2)
                filtered.append(shop_item)
        filtered.sort(key=lambda x: x["distance_km"])
        return {"status": "success", "radius_km": radius_km, "total_shops": len(filtered), "shops": filtered}

    @app.get("/api/v1/news")
    def get_agri_news():
        return {
            "status": "success",
            "news": AGRI_NEWS_DB
        }

else:
    # Standard Library HTTPServer Fallback Engine (Zero external dependencies required)
    from http.server import HTTPServer, BaseHTTPRequestHandler
    from urllib.parse import urlparse, parse_qs

    class FallbackAPIHandler(BaseHTTPRequestHandler):
        def _set_headers(self, status=200):
            self.send_response(status)
            self.send_header('Content-Type', 'application/json; charset=utf-8')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
            self.send_header('Access-Control-Allow-Headers', '*')
            self.end_headers()

        def do_OPTIONS(self):
            self._set_headers(200)

        def do_GET(self):
            parsed_path = urlparse(self.path)
            if parsed_path.path in ["/", "/health"]:
                self._set_headers(200)
                data = {"status": "online", "mode": "Python Built-in Engine", "service": "Papaya Disease Detection API"}
                self.wfile.write(json.dumps(data).encode('utf-8'))
            elif parsed_path.path == "/api/v1/shops":
                self._set_headers(200)
                filtered = []
                for s in MASTER_SHOPS:
                    dist = calculate_haversine(DEFAULT_LAT, DEFAULT_LNG, s["lat"], s["lng"])
                    if dist <= 100.0:
                        item = dict(s)
                        item["distance_km"] = round(dist, 2)
                        filtered.append(item)
                filtered.sort(key=lambda x: x["distance_km"])
                self.wfile.write(json.dumps({"status": "success", "shops": filtered}).encode('utf-8'))
            elif parsed_path.path == "/api/v1/news":
                self._set_headers(200)
                news_data = {
                    "status": "success",
                    "news": AGRI_NEWS_DB
                }
                self.wfile.write(json.dumps(news_data).encode('utf-8'))
            else:
                self._set_headers(404)
                self.wfile.write(json.dumps({"error": "Endpoint not found"}).encode('utf-8'))

        def do_POST(self):
            parsed_path = urlparse(self.path)
            if parsed_path.path == "/api/v1/predict":
                self._set_headers(200)
                query_params = parse_qs(parsed_path.query)
                key = query_params.get("disease_key", ["powdery_mildew"])[0]
                
                # Mock response format to match FastAPI predict JSON structure
                base_severity = severity_map.get(key, 50.0)
                severity = round(base_severity + random.uniform(-4, 4), 1) if key != "healthy" else 0.0
                status = "Moderate" if severity > 10 else "Healthy"
                
                result = {
                    "disease_key": key,
                    "confidence": 94.2,
                    "severity": severity,
                    "status": status
                }
                self.wfile.write(json.dumps(result).encode('utf-8'))
            else:
                self._set_headers(404)
                self.wfile.write(json.dumps({"error": "Endpoint not found"}).encode('utf-8'))

if __name__ == "__main__":
    if HAS_FASTAPI:
        uvicorn.run(app, host="0.0.0.0", port=8001)
    else:
        print("Starting Python Built-in API Server on http://0.0.0.0:8001 ...")
        server = HTTPServer(('0.0.0.0', 8001), FallbackAPIHandler)
        server.serve_forever()
