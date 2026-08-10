import tensorflow as tf
import os

def get_data_loaders(data_dir, batch_size=16, img_size=(224, 224), val_split=0.2):
    """
    Loads images from the specified directory, splits into training/validation sets,
    and applies on-the-fly data augmentation.
    """
    if not os.path.exists(data_dir):
        raise FileNotFoundError(f"Directory not found: {data_dir}")

    print(f"[INFO] Loading images from {data_dir}...")
    
    # Load training dataset
    train_ds = tf.keras.utils.image_dataset_from_directory(
        data_dir,
        validation_split=val_split,
        subset="training",
        seed=123,
        image_size=img_size,
        batch_size=batch_size,
        label_mode='categorical'
    )

    # Load validation dataset
    val_ds = tf.keras.utils.image_dataset_from_directory(
        data_dir,
        validation_split=val_split,
        subset="validation",
        seed=123,
        image_size=img_size,
        batch_size=batch_size,
        label_mode='categorical'
    )

    # Save class names before mapping transforms
    class_names = train_ds.class_names
    print(f"[INFO] Detected classes: {class_names}")

    # Define data augmentation pipeline for robust real-world performance
    # Focus on SHAPE and ROTATION to help differentiate from other leaves
    data_augmentation = tf.keras.Sequential([
        tf.keras.layers.RandomFlip("horizontal_and_vertical"),
        tf.keras.layers.RandomRotation(0.4), # Increased for multi-angle shape learning
        tf.keras.layers.RandomZoom(0.3),     # Increased to handle various distances
        tf.keras.layers.RandomContrast(0.2),
        tf.keras.layers.RandomTranslation(0.1, 0.1),
    ])

    # Optimize data pipeline performance using prefetching
    AUTOTUNE = tf.data.AUTOTUNE
    train_ds = train_ds.map(lambda x, y: (data_augmentation(x, training=True), y), num_parallel_calls=AUTOTUNE)
    train_ds = train_ds.prefetch(buffer_size=AUTOTUNE)
    val_ds = val_ds.prefetch(buffer_size=AUTOTUNE)

    return train_ds, val_ds, class_names