import os
import shutil

base_dir = r"C:\Users\prana\projects\Papaya-Disease-Detection\papaya_disease_system\data\raw"
dataset_dir = os.path.join(base_dir, "Dataset", "papaya main dataset")

mapping = {
    "healthy_leaf": "healthy",
    "Bacterial_Blight": "leaf_curl",
    "Carica_Insect_Hole": "powdery_mildew",
    "Yellow_Necrotic_Spots_Holes": "ringspot_virus"
}

for src_folder, dst_folder in mapping.items():
    src_path = os.path.join(dataset_dir, src_folder)
    dst_path = os.path.join(base_dir, dst_folder)

    if os.path.exists(src_path):
        print(f"Moving files from {src_folder} to {dst_folder}...")
        for img in os.listdir(src_path):
            shutil.move(os.path.join(src_path, img), os.path.join(dst_path, img))

# Clean up
shutil.rmtree(os.path.join(base_dir, "Dataset"))
print("Done!")
