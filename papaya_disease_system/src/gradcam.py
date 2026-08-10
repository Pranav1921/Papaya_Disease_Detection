from __future__ import annotations

from typing import Any, Optional

import numpy as np


def get_gradcam_overlay(model: Any, img_array: Optional[np.ndarray]) -> Optional[np.ndarray]:
    """Return a lightweight Grad-CAM-style heatmap when TensorFlow is available.

    The app only needs a useful visual explanation when the model can be loaded.
    If TensorFlow is missing or the model structure is incompatible, the function
    returns None so the UI can continue with the original image.
    """
    if model is None or img_array is None:
        return None

    try:
        import tensorflow as tf
    except ImportError:
        return None

    try:
        conv_layer = None
        for layer in reversed(model.layers):
            if isinstance(layer, tf.keras.layers.Conv2D):
                conv_layer = layer
                break

        if conv_layer is None:
            return None

        grad_model = tf.keras.models.Model(
            inputs=model.input,
            outputs=[conv_layer.output, model.output],
        )

        with tf.GradientTape() as tape:
            conv_outputs, predictions = grad_model(img_array, training=False)
            class_idx = int(np.argmax(predictions[0]))
            loss = predictions[:, class_idx]

        grads = tape.gradient(loss, conv_outputs)
        pooled_grads = tf.reduce_mean(grads, axis=(0, 1, 2))
        heatmap = tf.reduce_mean(tf.multiply(pooled_grads, conv_outputs[0]), axis=-1)
        heatmap = tf.maximum(heatmap, 0)
        heatmap = heatmap / tf.math.reduce_max(heatmap)
        heatmap = heatmap.numpy()
        return np.uint8(255 * heatmap)
    except Exception:
        return None
