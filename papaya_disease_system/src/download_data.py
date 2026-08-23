import os
import shutil
import kagglehub

def setup_dataset():
    print("[INFO] Downloading dataset from Kaggle...")
    # Download latest version from Kaggle
    try:
        cache_path = kagglehub.dataset_download("ajithdari/papaya-leaf-disease-dataset")
        print(f"[SUCCESS] Downloaded to cache: {cache_path}")
    except Exception as e:
        print(f"[ERROR] Kaggle download failed: {e}")
        return

    # Define our target project directory relative to this script
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    target_dir = os.path.join(base_dir, "data", "raw")
    os.makedirs(target_dir, exist_ok=True)

    # Class Mapping (Kaggle folder name -> Our project folder name)
    # This ensures the model is trained with the same order as in api_server.py
    # Expected in api_server.py: ['healthy', 'leaf_curl', 'powdery_mildew', 'ringspot_virus', 'background']
    mapping = {
        "healthy": "healthy",
        "Healthy": "healthy",
        "leaf_curl": "leaf_curl",
        "Leaf Curl": "leaf_curl",
        "Leaf_curl": "leaf_curl",
        "powdery_mildew": "powdery_mildew",
        "Powdery Mildew": "powdery_mildew",
        "Powdery_mildew": "powdery_mildew",
        "ringspot_virus": "ringspot_virus",
        "Ringspot Virus": "ringspot_virus",
        "Ringspot_virus": "ringspot_virus"
    }

    print(f"[INFO] Organizing files into '{target_dir}'...")
    
    # Process the downloaded files
    for item in os.listdir(cache_path):
        source_item = os.path.join(cache_path, item)

        if os.path.isdir(source_item):
            # Check if this folder maps to one of our classes
            if item in mapping:
                dest_name = mapping[item]
                target_item = os.path.join(target_dir, dest_name)

                # Create class folder if missing
                os.makedirs(target_item, exist_ok=True)

                print(f" -> Copying images for class: {dest_name}...")
                count = 0
                for img in os.listdir(source_item):
                    if img.lower().endswith(('.png', '.jpg', '.jpeg')):
                        shutil.copy2(os.path.join(source_item, img), os.path.join(target_item, img))
                        count += 1
                print(f"    - Copied {count} images.")
            else:
                print(f" [SKIP] Folder '{item}' does not match any known class.")

    # Create background folder if it doesn't exist
    bg_dir = os.path.join(target_dir, "background")
    if not os.path.exists(bg_dir):
        os.makedirs(bg_dir)
        print("\n[NOTE] 'background' folder created. Please add images of other plants (Mango, etc.) here manually.")

    print("\n[SUCCESS] Dataset is organized and ready!")
    print("Next step: Run 'python src/train.py' to retrain the model.")

if __name__ == "__main__":
    setup_dataset()
