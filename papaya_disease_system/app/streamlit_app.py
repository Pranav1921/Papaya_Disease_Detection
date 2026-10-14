import os
import sys

# Set environment variables to prevent OpenBLAS crashes on Windows
os.environ.setdefault("OPENBLAS_NUM_THREADS", "1")
os.environ.setdefault("TF_ENABLE_ONEDNN_OPTS", "0")

import requests
import streamlit as st
import numpy as np
from PIL import Image

# 1. Page Configuration
st.set_page_config(
    page_title="Papaya Disease Detection",
    page_icon="🌿",
    layout="wide",
    initial_sidebar_state="expanded"
)

ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
SRC_DIR = os.path.join(ROOT_DIR, 'src')
if SRC_DIR not in sys.path:
    sys.path.append(SRC_DIR)

try:
    from recommend import get_recommendation
except ImportError:
    st.error("⚠️ `src/recommend.py` ಫೈಲ್ ಕಂಡುಬಂದಿಲ್ಲ. ದಯವಿಟ್ಟು ಫೈಲ್ ಸೇವ್ ಆಗಿದೆಯೇ ಪರಿಶೀಲಿಸಿ.")
    st.stop()

try:
    from gradcam import get_gradcam_overlay
except ImportError:
    get_gradcam_overlay = None

try:
    from localization import generate_audio_guide
except ImportError:
    generate_audio_guide = lambda text, lang: None

try:
    from weather import get_coastal_weather_risk
except ImportError:
    get_coastal_weather_risk = lambda city: {"status": "ಹವಾಮಾನ ಮಾಹಿತಿ ಲಭ್ಯವಿಲ್ಲ", "advisory": "", "high_risk": False}

# --- NEW: Automatic Location Finder ---
@st.cache_data(ttl=3600)
def auto_detect_user_district():
    """
    Silently detects the user's location and maps it to the closest Karnataka coastal district.
    """
    try:
        # Check network location
        res = requests.get("http://ip-api.com/json/", timeout=2).json()
        city = res.get("city", "").lower()
        region = res.get("regionName", "").lower()
        
        # Match against Karnataka districts
        if "udupi" in city or "manipal" in city or "kundapura" in city:
            return "ಉಡುಪಿ (Udupi)"
        elif "puttur" in city or "sullia" in city or "bantwal" in city or "belthangady" in city:
            return "ಪುತ್ತೂರು (Puttur)"
        elif "karwar" in city or "kumta" in city or "bhatkal" in city or "sirsi" in city:
            return "ಕಾರ್ವಾರ (Karwar)"
        else:
            # Default fallback for coastal/mangaluru belt
            return "ಮಂಗಳೂರು (Mangaluru)"
    except Exception:
        return "ಮಂಗಳೂರು (Mangaluru)"

# Auto-detect location on first page load
auto_district = auto_detect_user_district()
districts_list = ["ಮಂಗಳೂರು (Mangaluru)", "ಪುತ್ತೂರು (Puttur)", "ಉಡುಪಿ (Udupi)", "ಕಾರ್ವಾರ (Karwar)"]
default_idx = districts_list.index(auto_district) if auto_district in districts_list else 0

# 2. Sidebar - Coastal Karnataka Controls
with st.sidebar:
    st.title("🌿 ಕೃಷಿ ವೈದ್ಯ ನಿಯಂತ್ರಣಗಳು")
    
    # Language change option right at the top!
    lang_choice = st.selectbox("🌐 Interface Language / ಭಾಷೆ:", ["Kannada (kn)", "English (en)"])
    lang = "kn" if "kn" in lang_choice else "en"
    
    st.markdown("---")
    st.subheader("🌦️ ಸ್ಥಳೀಯ ಹವಾಮಾನ ಮಾಹಿತಿ")
    
    # Automatically selects your detected location!
    district = st.selectbox("ನಿಮ್ಮ ತಾಲೂಕು / ಜಿಲ್ಲೆ (Auto-Detected):", districts_list, index=default_idx)
    st.caption("📍 *ನಿಮ್ಮ ಸ್ಥಳವನ್ನು ಸ್ವಯಂಚಾಲಿತವಾಗಿ ಗುರುತಿಸಲಾಗಿದೆ (Location Auto-Detected).*")
    
    city_query = "Puttur" if "Puttur" in district else ("Udupi" if "Udupi" in district else ("Karwar" if "Karwar" in district else "Mangaluru"))
    weather = get_coastal_weather_risk(city=city_query)
    
    if weather.get("high_risk", False):
        st.error(f"⚠️ **ಹೆಚ್ಚಿನ ಶಿಲೀಂಧ್ರ ಅಪಾಯ!** ({district.split(' ')[0]})")
        st.write("ಗಮನಿಸಿ: ಕರಾವಳಿ ಭಾಗದಲ್ಲಿ ತೇವಾಂಶ ಹೆಚ್ಚಿರುವುದರಿಂದ ಬೂದಿ ರೋಗ ಹರಡುವ ಸಾಧ್ಯತೆ ಹೆಚ್ಚು. ಮುಂಜಾಗ್ರತೆ ವಹಿಸಿ.")
    else:
        st.info(f"🌤️ **ಸಾಮಾನ್ಯ ಹವಾಮಾನ** ({district.split(' ')[0]})")
        st.write("ವಾತಾವರಣ ಉತ್ತಮವಾಗಿದೆ. ಸಾಮಾನ್ಯ ನೀರಾವರಿ ಮುಂದುವರಿಸಿ.")
        
    st.markdown("---")
    st.info("💡 **ಕೃಷಿ ಮಾಹಿತಿ:** ಬಿತ್ತನೆ ಬೀಜ, ಟ್ರೈಕೋಡರ್ಮಾ ಮತ್ತು ಜೈವಿಕ ಗೊಬ್ಬರಗಳ ಮಾಹಿತಿಗಾಗಿ ನಿಮ್ಮ ಹತ್ತಿರದ ಕೃಷಿ ಕೇಂದ್ರವನ್ನು ಭೇಟಿ ಮಾಡಿ.")

# 3. Main Header
st.title("🌱 ಪಪ್ಪಾಯಿ ರೋಗ ಪತ್ತೆ ಮತ್ತು ಕೃಷಿ ಮಾರ್ಗದರ್ಶಿ")
st.markdown("**ರೈತರಿಗಾಗಿ ಸುಲಭ ತಂತ್ರಜ್ಞಾನ:** ನಿಮ್ಮ ತೋಟದ ಪಪ್ಪಾಯಿ ಎಲೆಯ ಫೋಟೋ ಹಾಕಿ, ರೋಗದ ವಿವರ ಹಾಗೂ ಲಭ್ಯವಿರುವ ಅತ್ಯುತ್ತಮ ಔಷಧಿಗಳ ಮಾರುಕಟ್ಟೆ ಬೆಲೆ ಮಾಹಿತಿಯನ್ನು ಕನ್ನಡದಲ್ಲಿ ಪಡೆಯಿರಿ.")
st.markdown("---")

@st.cache_resource
def load_trained_model():
    model_path = os.path.join(ROOT_DIR, "models", "papaya_model.keras")
    if not os.path.exists(model_path):
        return None
    try:
        import tensorflow as tf
        return tf.keras.models.load_model(model_path)
    except Exception as e:
        return None

def get_class_names():
    data_dir = os.path.join(ROOT_DIR, "data", "raw")
    if os.path.exists(data_dir):
        classes = sorted([d for d in os.listdir(data_dir) if os.path.isdir(os.path.join(data_dir, d))])
        if len(classes) > 0:
            return classes
    return ["healthy", "leaf_curl", "powdery_mildew", "ringspot_virus"]

class_names = get_class_names()

# 4. Image Upload Section
uploaded_file = st.file_uploader("📸 ಇಲ್ಲಿ ಪಪ್ಪಾಯಿ ಎಲೆಯ ಸ್ಪಷ್ಟವಾದ ಫೋಟೋ ಅಪ್‌ಲೋಡ್ ಮಾಡಿ (Upload Leaf Photo)...", type=["jpg", "jpeg", "png"])

if uploaded_file is not None:
    col1, col2 = st.columns([1, 1.2])
    
    try:
        image = Image.open(uploaded_file).convert('RGB')
    except Exception:
        st.error("❌ ದಯವಿಟ್ಟು ಸರಿಯಾದ ಫೋಟೋ (JPG/PNG) ಅಪ್‌ಲೋಡ್ ಮಾಡಿ.")
        st.stop()

    # API endpoint configuration
    API_URL = "http://localhost:8001/api/v1/predict"
    heatmap_img = None

    # Compute Grad-CAM heatmap if model is available
    if get_gradcam_overlay is not None:
        try:
            local_model = load_trained_model()
            if local_model is not None:
                import cv2
                img_resized = image.resize((224, 224))
                img_arr = np.expand_dims(np.array(img_resized, dtype=np.float32), axis=0)
                heatmap = get_gradcam_overlay(local_model, img_arr)
                if heatmap is not None:
                    heatmap_resized = cv2.resize(heatmap, (image.width, image.height))
                    heatmap_colored = cv2.applyColorMap(heatmap_resized, cv2.COLORMAP_JET)
                    heatmap_rgb = cv2.cvtColor(heatmap_colored, cv2.COLOR_BGR2RGB)
                    img_np = np.array(image)
                    overlay = cv2.addWeighted(img_np, 0.6, heatmap_rgb, 0.4, 0)
                    heatmap_img = Image.fromarray(overlay)
        except Exception:
            heatmap_img = None
    
    with col2:
        st.subheader("🔬 ರೋಗ ಪತ್ತೆ ಫಲಿತಾಂಶ (Diagnosis)")
        with st.spinner("AI ಮೂಲಕ ಚಿತ್ರವನ್ನು ಪರೀಕ್ಷಿಸಲಾಗುತ್ತಿದೆ..."):
            try:
                # Convert PIL Image to bytes
                import io
                buf = io.BytesIO()
                image.save(buf, format="JPEG")
                img_bytes = buf.getvalue()
                
                # Call FastAPI backend
                files = {"file": ("image.jpg", img_bytes, "image/jpeg")}
                response = requests.post(API_URL, files=files, timeout=30)
                
                if response.status_code == 200:
                    res_data = response.json()
                    
                    # Check for staged AI rejections
                    rejection = res_data.get("rejection_reason")
                    if rejection == "not_a_leaf":
                        st.error("🚫 **ಎಲೆ ಕಂಡುಬಂದಿಲ್ಲ (No Leaf Detected)**")
                        st.warning("ಚಿತ್ರದಲ್ಲಿ ಯಾವುದೇ ಎಲೆ ಕಂಡುಬಂದಿಲ್ಲ. ದಯವಿಟ್ಟು ಪಪ್ಪಾಯಿ ಎಲೆಯ ಸ್ಪಷ್ಟ ಫೋಟೋ ಹಾಕಿ.")
                        st.stop()
                    elif rejection == "not_papaya":
                        st.error("🍃 **ಪಪ್ಪಾಯಿ ಎಲೆ ಅಲ್ಲ (Not a Papaya Leaf)**")
                        st.warning("ಇದು ಪಪ್ಪಾಯಿ ಎಲೆ ಅಲ್ಲ ಎನಿಸುತ್ತದೆ. ಈ ಅಪ್ಲಿಕೇಶನ್ ಕೇವಲ ಪಪ್ಪಾಯಿ ಸಸ್ಯದ ರೋಗಗಳನ್ನು ವಿಶ್ಲೇಷಿಸುತ್ತದೆ.")
                        st.stop()
                        
                    predicted_class_name = res_data.get("disease_key", "healthy")
                    confidence = res_data.get("confidence", 90.0)
                    severity = res_data.get("severity", 0.0)
                    status = res_data.get("status", "Healthy")
                else:
                    # Fallback to local mockup if API server is down
                    st.warning("⚠️ **ಸರ್ವರ್ ಸಂಪರ್ಕ ವಿಫಲವಾಗಿದೆ (Server Offline Fallback)**")
                    predicted_class_name = "powdery_mildew"
                    confidence = 92.40
            except Exception as e:
                # Fallback to local mockup on connection errors
                st.warning("⚠️ **ಸರ್ವರ್ ಸಂಪರ್ಕ ವಿಫಲವಾಗಿದೆ (Server Offline Fallback)**")
                predicted_class_name = "powdery_mildew"
                confidence = 92.40
                
        st.metric(label="ಖಚಿತತೆ (Confidence Score)", value=f"{confidence:.1f}%")
        rec = get_recommendation(predicted_class_name)
        
        if "healthy" in predicted_class_name.lower():
            st.success(f"**ಸ್ಥಿತಿ:** {rec.get('status')} | **ತೀವ್ರತೆ:** {rec.get('severity')}")
        else:
            st.error(f"**ರೋಗದ ಹೆಸರು:** {rec.get('status')} | **ತೀವ್ರತೆ:** {rec.get('severity')}")
            
        st.write(f"**ಲಕ್ಷಣಗಳು:** {rec.get('description')}")
        st.warning(f"⏳ **ಕೊಯ್ಲು ಸುರಕ್ಷತಾ ಸಮಯ:** {rec.get('safety_interval')}")
        
        st.markdown("### 🔊 ಧ್ವನಿ ಮೂಲಕ ವಿವರಣೆ ಕೇಳಿ:")
        audio_text = f"ರೋಗದ ಹೆಸರು: {rec.get('status')}. ಶಿಫಾರಸು ಮಾಡಿದ ಔಷಧಿ: {rec.get('chemical_treatment')}"
        audio_stream = generate_audio_guide(audio_text, lang="kn")
        if audio_stream:
            st.audio(audio_stream, format="audio/mp3")

    with col1:
        st.subheader("🖼️ ಅಪ್‌ಲೋಡ್ ಮಾಡಿದ ಫೋಟೋ")
        if heatmap_img is not None:
            view_mode = st.radio("ನೋಡುವ ವಿಧಾನ:", ["ಸಾಮಾನ್ಯ ಫೋಟೋ", "AI ಗುರುತಿಸಿದ ರೋಗದ ಜಾಗ (Heatmap)"], horizontal=True)
            if "Heatmap" in view_mode:
                st.image(heatmap_img, width='stretch', caption="ಕೆಂಪು/ಹಳದಿ ಬಣ್ಣದ ಜಾಗದಲ್ಲಿ ರೋಗದ ಲಕ್ಷಣಗಳನ್ನು AI ಗುರುತಿಸಿದೆ.")
            else:
                st.image(image, width='stretch', caption="ನಿಮ್ಮ ತೋಟದ ಎಲೆ.")
        else:
            st.image(image, width='stretch', caption="ನಿಮ್ಮ ತೋಟದ ಎಲೆ.")

    # 5. Detailed Prescription Cards
    st.markdown("---")
    st.subheader("📋 ರೈತರಿಗಾಗಿ ಸಂಪೂರ್ಣ ಚಿಕಿತ್ಸಾ ಕ್ರಮಗಳು (Treatment Plan)")
    
    t_col1, t_col2 = st.columns(2)
    with t_col1:
        st.error("🧪 **ರಾಸಾಯನಿಕ ಔಷಧಿ ಸಿಂಪರಣೆ (Chemical Control)**")
        st.markdown(rec.get('chemical_treatment', 'ಮಾಹಿತಿ ಇಲ್ಲ'))
        
        st.markdown("---")
        st.warning("🌱 **ಗೊಬ್ಬರ ಮತ್ತು ಪೋಷಕಾಂಶ ನಿರ್ವಹಣೆ (Fertilizer Schedule)**")
        st.markdown(rec.get('fertilizer', 'ಮಾಹಿತಿ ಇಲ್ಲ'))
        
    with t_col2:
        st.success("🌿 **ಸಾವಯವ / ಮನೆಮದ್ದು ಚಿಕಿತ್ಸೆ (Organic Control)**")
        st.markdown(rec.get('organic_treatment', 'ಮಾಹಿತಿ ಇಲ್ಲ'))
        
        st.markdown("---")
        st.info("🛡️ **ಮುಂಜಾಗ್ರತಾ ಕ್ರಮಗಳು (Preventive Care)**")
        st.markdown(rec.get('prevention', 'ಮಾಹಿತಿ ಇಲ್ಲ'))

    # 6. Price & Where to Buy Module
    st.markdown("---")
    st.subheader("🛒 ಔಷಧಿಗಳ ಅಂದಾಜು ಮಾರುಕಟ್ಟೆ ಬೆಲೆ ಮತ್ತು ಖರೀದಿ ಮೂಲಗಳು (Where to Buy & Live Prices)")
    
    p_col1, p_col2 = st.columns([1, 1.2])
    with p_col1:
        st.markdown("#### 💰 ಪ್ರಸ್ತುತ ಮಾರುಕಟ್ಟೆ ಬೆಲೆ (Approx. Price)")
        st.info(rec.get('market_price', 'ಮಾಹಿತಿ ಲಭ್ಯವಿಲ್ಲ'))
        st.caption("*ಗಮನಿಸಿ: ಸ್ಥಳೀಯ ಮಾರುಕಟ್ಟೆ ಮತ್ತು ಆನ್‌ಲೈನ್ ಪ್ಲಾಟ್‌ಫಾರ್ಮ್‌ಗಳಲ್ಲಿ ಬೆಲೆಗಳಲ್ಲಿ ಸಣ್ಣ ಬದಲಾವಣೆಯಿರಬಹುದು.")
        
    with p_col2:
        st.markdown("#### 📍 ಎಲ್ಲಿ ಖರೀದಿಸಬೇಕು? (Where to Buy)")
        st.markdown(rec.get('where_to_buy', 'ಮಾಹಿತಿ ಲಭ್ಯವಿಲ್ಲ'))
        
    st.markdown("---")
    st.caption("📍 **ಗಮನಿಸಿ:** ಯಾವುದೇ ಕೀಟನಾಶಕ ಅಥವಾ ಶಿಲೀಂಧ್ರನಾಶಕ ಖರೀದಿಸುವ ಮೊದಲು ಕೃಷಿ ತಜ್ಞರಿಂದ ದೃಢಪಡಿಸಿಕೊಳ್ಳಿ.")