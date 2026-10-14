

import os
import sys

# Set environment variables to prevent OpenBLAS crashes on Windows
os.environ["OPENBLAS_NUM_THREADS"] = "1"
os.environ["TF_ENABLE_ONEDNN_OPTS"] = "0"

import traceback

def run_checks():
    print("=" * 60)
    print("STARTING PAPAYA DISEASE SYSTEM VERIFICATION")
    print("=" * 60)

    ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
    SRC_DIR = os.path.join(ROOT_DIR, 'src')
    MODELS_DIR = os.path.join(ROOT_DIR, 'models')
    APP_DIR = os.path.join(ROOT_DIR, 'app')
    sys.path.insert(0, SRC_DIR)
    sys.path.insert(0, APP_DIR)

    all_passed = True

    # 1. Check Models
    print("\n[1/6] Checking Model Files...")
    keras_model_path = os.path.join(MODELS_DIR, "papaya_model.keras")
    tflite_model_path = os.path.join(MODELS_DIR, "papaya_model.tflite")
    if os.path.exists(keras_model_path):
        print(f"  [OK] Keras model exists ({os.path.getsize(keras_model_path) / (1024*1024):.2f} MB)")
    else:
        print(f"  [FAIL] Keras model missing at {keras_model_path}")
        all_passed = False

    if os.path.exists(tflite_model_path):
        print(f"  [OK] TFLite model exists ({os.path.getsize(tflite_model_path) / (1024*1024):.2f} MB)")
    else:
        print(f"  [FAIL] TFLite model missing at {tflite_model_path}")
        all_passed = False

    # 2. Check Weather Module
    print("\n[2/6] Checking Weather Risk Assessment Module...")
    try:
        from weather import get_coastal_weather_risk
        districts = ["Mangaluru", "Puttur", "Udupi", "Karwar"]
        for d in districts:
            w = get_coastal_weather_risk(city=d)
            assert "status" in w, f"Missing status in weather output for {d}"
            assert "advisory" in w, f"Missing advisory in weather output for {d}"
            assert "high_risk" in w, f"Missing high_risk in weather output for {d}"
            print(f"  [OK] Weather check for {d}: High Risk={w['high_risk']}")
    except Exception as e:
        print(f"  [FAIL] Weather module check failed: {e}")
        traceback.print_exc()
        all_passed = False

    # 3. Check Recommendations Module
    print("\n[3/6] Checking Recommendations Module...")
    try:
        from recommend import get_recommendation
        classes = ['healthy', 'leaf_curl', 'powdery_mildew', 'ringspot_virus']
        for c in classes:
            rec = get_recommendation(c)
            assert rec is not None, f"Empty recommendation for {c}"
            assert "chemical_treatment" in rec, f"Missing chemical_treatment for {c}"
            assert "organic_treatment" in rec, f"Missing organic_treatment for {c}"
            print(f"  [OK] Recommendation for class '{c}' verified")
    except Exception as e:
        print(f"  [FAIL] Recommendations check failed: {e}")
        traceback.print_exc()
        all_passed = False

    # 4. Check Localization Module
    print("\n[4/6] Checking Localization Module...")
    try:
        from localization import generate_audio_guide
        print("  [OK] Localization module imported successfully")
    except Exception as e:
        print(f"  [FAIL] Localization check failed: {e}")
        all_passed = False

    # 5. Check API Server & FastAPI
    print("\n[5/6] Checking API Server & Dependencies...")
    try:
        import api_server
        print(f"  [OK] api_server imported successfully (HAS_FASTAPI={getattr(api_server, 'HAS_FASTAPI', False)}, HAS_TF={getattr(api_server, 'HAS_TF', False)})")
    except Exception as e:
        print(f"  [FAIL] API Server import failed: {e}")
        traceback.print_exc()
        all_passed = False

    # 6. Check Streamlit App Syntax
    print("\n[6/6] Checking Streamlit App...")
    try:
        streamlit_path = os.path.join(APP_DIR, "streamlit_app.py")
        with open(streamlit_path, "r", encoding="utf-8") as f:
            code = f.read()
        compile(code, streamlit_path, "exec")
        print("  [OK] streamlit_app.py compiles without syntax errors")
    except Exception as e:
        print(f"  [FAIL] Streamlit compilation failed: {e}")
        traceback.print_exc()
        all_passed = False

    print("\n" + "=" * 60)
    if all_passed:
        print("RESULT: ALL CHECKS PASSED -> YES")
    else:
        print("RESULT: SOME CHECKS FAILED -> NO")
    print("=" * 60)

if __name__ == "__main__":
    run_checks()
