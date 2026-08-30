"""
ForestGuard Wildlife Model - Fine-Tuning Script
Fine-tunes YOLO11n on a wildlife dataset containing 5 target classes:
Tiger, Elephant, Lion, Leopard, Bear.

Usage:
    python train_wildlife_model.py

Prerequisites:
    pip install ultralytics roboflow pyyaml

The script will:
1. Download the wildlife dataset from Roboflow (or use local data)
2. Create/validate the data.yaml configuration
3. Fine-tune YOLO11n for 50 epochs
4. Export best weights to models/forestguard_wildlife.pt
5. Update models/model_config.yaml with training metadata
"""

import os
import sys
import shutil
from datetime import datetime
from pathlib import Path

# ─── Configuration ──────────────────────────────────────────────────

BASE_DIR = Path(__file__).parent
MODELS_DIR = BASE_DIR / "models"
DATASETS_DIR = BASE_DIR / "datasets"
MODELS_DIR.mkdir(exist_ok=True)
DATASETS_DIR.mkdir(exist_ok=True)

# Training hyperparameters
BASE_MODEL = "yolo11n.pt"
EPOCHS = 50
IMGSZ = 640
BATCH_SIZE = 16
PATIENCE = 10
DEVICE = "0" if __import__("torch").cuda.is_available() else "cpu"

# Target classes
TARGET_CLASSES = {
    0: "tiger",
    1: "elephant",
    2: "lion",
    3: "leopard",
    4: "bear",
}

# Roboflow dataset configuration
# You can replace these with your own Roboflow project details
ROBOFLOW_API_KEY = os.getenv("ROBOFLOW_API_KEY", "")
ROBOFLOW_WORKSPACE = os.getenv("ROBOFLOW_WORKSPACE", "realtime-wildlife-detection-and-alert-system-for-railway-tracks-animal-dataset")
ROBOFLOW_PROJECT = os.getenv("ROBOFLOW_PROJECT", "animal-detection-9dl1v")
ROBOFLOW_VERSION = int(os.getenv("ROBOFLOW_VERSION", "1"))


def download_dataset_roboflow():
    """Download wildlife dataset from Roboflow Universe."""
    print("=" * 60)
    print("Downloading wildlife dataset from Roboflow...")
    print("=" * 60)

    try:
        from roboflow import Roboflow

        if not ROBOFLOW_API_KEY:
            print("\n[WARNING] ROBOFLOW_API_KEY not set.")
            print("To download the dataset automatically, set the environment variable:")
            print("  set ROBOFLOW_API_KEY=your_api_key_here")
            print("\nAlternatively, download the dataset manually:")
            print(f"  1. Visit: https://universe.roboflow.com/{ROBOFLOW_WORKSPACE}/{ROBOFLOW_PROJECT}")
            print("  2. Export in YOLOv8 format")
            print(f"  3. Extract to: {DATASETS_DIR / 'wildlife'}")
            print("\nExpected structure:")
            print("  datasets/wildlife/")
            print("    images/train/  (training images)")
            print("    images/val/    (validation images)")
            print("    labels/train/  (training labels)")
            print("    labels/val/    (validation labels)")
            return None

        rf = Roboflow(api_key=ROBOFLOW_API_KEY)
        project = rf.workspace(ROBOFLOW_WORKSPACE).project(ROBOFLOW_PROJECT)
        dataset = project.version(ROBOFLOW_VERSION).download(
            "yolov8",
            location=str(DATASETS_DIR / "wildlife")
        )
        print(f"Dataset downloaded to: {DATASETS_DIR / 'wildlife'}")
        return str(DATASETS_DIR / "wildlife" / "data.yaml")

    except ImportError:
        print("[ERROR] roboflow package not installed. Install with: pip install roboflow")
        return None
    except Exception as e:
        print(f"[ERROR] Failed to download dataset: {e}")
        return None


def create_data_yaml():
    """Create or validate data.yaml for training."""
    data_yaml_path = BASE_DIR / "data.yaml"

    # Check if dataset exists locally
    wildlife_dir = DATASETS_DIR / "wildlife"
    if wildlife_dir.exists():
        # Check for roboflow-downloaded data.yaml
        rf_yaml = wildlife_dir / "data.yaml"
        if rf_yaml.exists():
            print(f"Using existing data.yaml: {rf_yaml}")
            return str(rf_yaml)

    # Create default data.yaml
    yaml_content = f"""# ForestGuard Wildlife Detection Dataset
# Fine-tune YOLO11n to detect: Tiger, Elephant, Lion, Leopard, Bear

train: {DATASETS_DIR / 'wildlife' / 'images' / 'train'}
val: {DATASETS_DIR / 'wildlife' / 'images' / 'val'}

nc: 5
names:
  0: tiger
  1: elephant
  2: lion
  3: leopard
  4: bear
"""

    data_yaml_path.write_text(yaml_content, encoding="utf-8")
    print(f"Created data.yaml at: {data_yaml_path}")
    return str(data_yaml_path)


def check_dataset():
    """Verify dataset is ready for training."""
    wildlife_dir = DATASETS_DIR / "wildlife"
    train_imgs = wildlife_dir / "images" / "train"
    val_imgs = wildlife_dir / "images" / "val"
    train_labels = wildlife_dir / "labels" / "train"
    val_labels = wildlife_dir / "labels" / "val"

    issues = []
    for path, desc in [
        (train_imgs, "Training images"),
        (val_imgs, "Validation images"),
        (train_labels, "Training labels"),
        (val_labels, "Validation labels"),
    ]:
        if not path.exists():
            issues.append(f"  Missing: {desc} ({path})")
        else:
            count = len(list(path.iterdir()))
            print(f"  {desc}: {count} files")

    if issues:
        print("\n[WARNING] Dataset issues found:")
        for issue in issues:
            print(issue)
        return False

    return True


def train_model(data_yaml: str):
    """Fine-tune YOLO11n on the wildlife dataset."""
    print("\n" + "=" * 60)
    print(f"Starting YOLO11n Fine-Tuning")
    print(f"  Base Model: {BASE_MODEL}")
    print(f"  Device: {DEVICE}")
    print(f"  Epochs: {EPOCHS}")
    print(f"  Image Size: {IMGSZ}")
    print(f"  Batch Size: {BATCH_SIZE}")
    print(f"  Dataset: {data_yaml}")
    print("=" * 60)

    from ultralytics import YOLO

    # Load base model
    model = YOLO(BASE_MODEL)

    # Train
    results = model.train(
        data=data_yaml,
        epochs=EPOCHS,
        imgsz=IMGSZ,
        batch=BATCH_SIZE,
        patience=PATIENCE,
        device=DEVICE,
        project=str(BASE_DIR / "runs"),
        name="forestguard_wildlife",
        exist_ok=True,
        verbose=True,
        # Augmentation
        hsv_h=0.015,
        hsv_s=0.7,
        hsv_v=0.4,
        degrees=10.0,
        translate=0.1,
        scale=0.5,
        fliplr=0.5,
        mosaic=1.0,
    )

    return results


def export_model():
    """Export best weights to models/ directory."""
    runs_dir = BASE_DIR / "runs" / "forestguard_wildlife"
    best_weights = runs_dir / "weights" / "best.pt"

    if not best_weights.exists():
        print(f"[ERROR] Best weights not found at: {best_weights}")
        return False

    # Copy to models directory
    dest = MODELS_DIR / "forestguard_wildlife.pt"
    shutil.copy2(best_weights, dest)
    print(f"\nBest model exported to: {dest}")
    print(f"  Size: {dest.stat().st_size / (1024*1024):.1f} MB")

    # Update model_config.yaml
    config_path = MODELS_DIR / "model_config.yaml"
    config_content = f"""# ForestGuard Wildlife Detection - Model Configuration
# Auto-generated after fine-tuning

model_name: "forestguard_wildlife"
model_architecture: "YOLO11n"
model_version: "1.0.0"
training_date: "{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
export_format: "pytorch"

classes:
  0: tiger
  1: elephant
  2: lion
  3: leopard
  4: bear
num_classes: 5

training:
  base_model: "{BASE_MODEL}"
  epochs: {EPOCHS}
  imgsz: {IMGSZ}
  batch_size: {BATCH_SIZE}
  device: "{DEVICE}"

inference:
  confidence_threshold: 0.35
  verification_threshold: 0.70
  iou_threshold: 0.45
  imgsz: {IMGSZ}
"""
    config_path.write_text(config_content, encoding="utf-8")
    print(f"Model config updated: {config_path}")
    return True


def export_onnx():
    """Optionally export to ONNX format."""
    dest = MODELS_DIR / "forestguard_wildlife.pt"
    if not dest.exists():
        print("[SKIP] No model to export to ONNX")
        return

    print("\nExporting to ONNX format...")
    from ultralytics import YOLO
    model = YOLO(str(dest))
    model.export(format="onnx", imgsz=640)
    print("ONNX export complete!")


def main():
    print("\n" + "=" * 60)
    print("ForestGuard Wildlife Model - Fine-Tuning Pipeline")
    print("Target Classes: Tiger, Elephant, Lion, Leopard, Bear")
    print("=" * 60)

    # Step 1: Download or locate dataset
    print("\n[1/5] Preparing dataset...")
    data_yaml = download_dataset_roboflow()
    if data_yaml is None:
        data_yaml = create_data_yaml()

    # Step 2: Validate dataset
    print("\n[2/5] Validating dataset...")
    if not check_dataset():
        print("\n[!] Dataset validation failed.")
        print("    Please download/prepare the dataset first.")
        print("    Run with ROBOFLOW_API_KEY set, or manually prepare the dataset.")
        sys.exit(1)

    # Step 3: Train
    print("\n[3/5] Training model...")
    results = train_model(data_yaml)

    # Step 4: Export
    print("\n[4/5] Exporting model...")
    if export_model():
        print("Model exported successfully!")

    # Step 5: Optional ONNX export
    print("\n[5/5] ONNX export (optional)...")
    try:
        export_onnx()
    except Exception as e:
        print(f"[SKIP] ONNX export failed: {e}")

    print("\n" + "=" * 60)
    print("TRAINING COMPLETE!")
    print(f"Model ready at: {MODELS_DIR / 'forestguard_wildlife.pt'}")
    print("Restart the AI camera service to use the new model.")
    print("=" * 60)


if __name__ == "__main__":
    main()
