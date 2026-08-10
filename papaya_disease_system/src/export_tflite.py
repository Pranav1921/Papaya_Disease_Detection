# src/export_tflite.py
import os
import tensorflow as tf

def export_to_tflite():
    model_path = os.path.join("models", "papaya_model.keras")
    tflite_path = os.path.join("models", "papaya_model.tflite")
    
    if not os.path.exists(model_path):
        print(f"[ERROR] Model not found at {model_path}. Please run src/train.py first!")
        return

    print("[INFO] Loading trained Keras model...")
    model = tf.keras.models.load_model(model_path)
    
    print("[INFO] Converting to TensorFlow Lite with default quantization...")
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    # Quantization compresses 32-bit floats down to efficient 8-bit integers
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_model = converter.convert()
    
    with open(tflite_path, 'wb') as f:
        f.write(tflite_model)
        
    size_mb = os.path.getsize(tflite_path) / (1024 * 1024)
    print(f"[SUCCESS] TFLite model successfully saved to: {tflite_path} ({size_mb:.2f} MB)")

if __name__ == "__main__":
    export_to_tflite()