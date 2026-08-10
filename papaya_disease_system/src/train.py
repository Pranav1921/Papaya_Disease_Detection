import os
import tensorflow as tf
from tensorflow.keras import layers, models
from tensorflow.keras.applications import MobileNetV2
from preprocess import get_data_loaders

def create_model(input_shape=(224, 224, 3), num_classes=4):
    """
    Builds a transfer learning model using MobileNetV2 as the base
    and appends custom classification layers.
    """
    # Base model: Pre-trained MobileNetV2 (excluding top ImageNet classification layers)
    base_model = MobileNetV2(
        input_shape=input_shape,
        include_top=False,
        weights='imagenet'
    )
    
    # Freeze base model weights initially so we only train our custom head
    base_model.trainable = False

    # Build custom classification layers
    inputs = layers.Input(shape=input_shape)
    
    # Preprocessing layer: MobileNetV2 expects pixel values scaled between [-1, 1]
    # Enhanced Augmentation to focus on SHAPE and PATTERN rather than just color
    x = layers.RandomFlip("horizontal_and_vertical")(inputs)
    x = layers.RandomRotation(0.3)(x)
    x = layers.RandomZoom(0.2)(x)
    x = layers.RandomTranslation(0.1, 0.1)(x)
    x = layers.RandomContrast(0.2)(x)
    x = layers.RandomBrightness(0.2)(x) # Added to handle different camera exposures

    x = layers.Rescaling(1./127.5, offset=-1)(x)
    
    # Pass through base model
    # We use MobileNetV2 features but add more capacity to learn complex leaf textures
    x = base_model(x, training=False)
    
    # Custom Dense & Regularization layers
    x = layers.GlobalAveragePooling2D()(x)
    x = layers.BatchNormalization()(x)
    x = layers.Dropout(0.5)(x)

    # Feature extraction layer for shape patterns
    x = layers.Dense(256, activation='relu')(x)
    x = layers.BatchNormalization()(x)
    x = layers.Dropout(0.4)(x)

    # Deep pattern recognition layer
    x = layers.Dense(128, activation='relu')(x)
    x = layers.BatchNormalization()(x)
    x = layers.Dropout(0.3)(x)

    # Output layer using softmax for multi-class probability classification
    outputs = layers.Dense(num_classes, activation='softmax')(x)
    
    model = models.Model(inputs, outputs, name="Papaya_MobileNetV2")
    return model

def main():
    # Use path relative to the script's actual location to avoid directory errors
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    data_dir = os.path.join(base_dir, "data", "raw")
    
    # Check if directory exists
    if not os.path.exists(data_dir):
        print(f"\n[ERROR] Data directory not found at: {data_dir}")
        return

    # Check if subdirectories actually contain files
    subdirs = [os.path.join(data_dir, d) for d in os.listdir(data_dir) if os.path.isdir(os.path.join(data_dir, d))]
    if not subdirs or all(len(os.listdir(d)) == 0 for d in subdirs):
        print("\n[ERROR] Your 'data/raw/' subfolders are empty!")
        print("Please place papaya leaf images into their respective folders:")
        print(" -> data/raw/healthy/")
        print(" -> data/raw/ringspot_virus/")
        print(" -> data/raw/leaf_curl/")
        print(" -> data/raw/powdery_mildew/\n")
        return

    # Load data
    train_ds, val_ds, class_names = get_data_loaders(data_dir, batch_size=16)
    num_classes = len(class_names)
    print(f"[INFO] Found {num_classes} classes: {class_names}")

    # Build & compile model
    print(f"[INFO] Building MobileNetV2 model for {num_classes} classes...")
    model = create_model(num_classes=num_classes)
    
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=0.001),
        loss='categorical_crossentropy',
        metrics=['accuracy']
    )
    
    model.summary()

    # Define callbacks to automatically save the best model
    model_save_dir = os.path.join(base_dir, "models")
    os.makedirs(model_save_dir, exist_ok=True)
    model_save_path = os.path.join(model_save_dir, "papaya_model.keras")

    callbacks = [
        tf.keras.callbacks.EarlyStopping(monitor='val_loss', patience=5, restore_best_weights=True),
        tf.keras.callbacks.ModelCheckpoint(filepath=model_save_path, monitor='val_loss', save_best_only=True)
    ]

    # Train the model: STAGE 1 (Train only the Head)
    print("\n[INFO] Stage 1: Training custom classification head...")
    model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=10,
        callbacks=callbacks
    )

    # Train the model: STAGE 2 (Fine-tuning)
    print("\n[INFO] Stage 2: Fine-tuning base model layers for shape patterns...")

    # Unfreeze the base model
    base_model = model.get_layer("mobilenetv2_1.00_224")
    base_model.trainable = True

    # Freeze all layers except the last 30
    # This keeps general low-level filters but adapts high-level shape filters
    fine_tune_at = len(base_model.layers) - 30
    for layer in base_model.layers[:fine_tune_at]:
        layer.trainable = False

    # Re-compile with a MUCH lower learning rate for fine-tuning
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=0.00001),
        loss='categorical_crossentropy',
        metrics=['accuracy']
    )

    history = model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=15,
        callbacks=callbacks
    )
    
    print(f"\n[SUCCESS] Fine-tuning complete! Best model saved to: {model_save_path}")

if __name__ == "__main__":
    main()