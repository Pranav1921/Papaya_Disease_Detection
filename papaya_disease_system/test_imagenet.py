import sys
import traceback

import tensorflow as tf
from tensorflow.keras.applications.mobilenet_v2 import MobileNetV2, decode_predictions, preprocess_input
import numpy as np

try:
    print("Loading MobileNetV2...")
    model_imagenet = MobileNetV2(weights='imagenet')
    print("MobileNetV2 loaded successfully.")
except Exception:
    traceback.print_exc()
    # Exit non-zero so this smoke check actually fails when the model is broken.
    sys.exit(1)
