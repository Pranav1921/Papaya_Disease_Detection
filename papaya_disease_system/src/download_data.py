import os
import shutil
import kagglehub

def setup_dataset():
    print("[INFO] Downloading dataset from Kaggle...")
    # Download latest version from Kaggle
    cache_path = kagglehub.dataset_download("ajithdari/papaya-leaf-disease-dataset")
    print(f"[SUCCESS] Downloaded to cache: {cache_path}")

    # Define our target project directory relative to this script
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    target_dir = os.path.join(base_dir, "data", "raw")
    os.makedirs(target_dir, exist_ok=True)

    print(f"[INFO] Copying files from cache to '{target_dir}'...")
    
    # Copy all folders/files from the Kaggle cache into our data/raw folder
    for item in os.listdir(cache_path):
        source_item = os.path.join(cache_path, item)
        target_item = os.path.join(target_dir, item)
        
        if os.path.isdir(source_item):
            # If folder already exists, copy tree overwriting contents
            if os.path.exists(target_item):
                shutil.rmtree(target_item)
            shutil.copytree(source_item, target_item)
            print(f" -> Copied folder: {item}")
        else:
            shutil.copy2(source_item, target_item)
            print(f" -> Copied file: {item}")

    print("\n[SUCCESS] Dataset is fully set up in your 'data/raw/' folder!")
    print("You can now run: python src/train.py")

if __name__ == "__main__":
    setup_dataset()