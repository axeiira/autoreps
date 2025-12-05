#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Training model Plank + Squat untuk Exercise-Correction repo.

- Input:
    core/plank_model/train.csv
    core/squat_model/train.csv

- Output:
    core/plank_model/model/plank_mlp.h5
    core/plank_model/model/plank_mlp.tflite
    core/plank_model/model/meta.json
    core/plank_model/model/plank_training_curve.png
    core/plank_model/model/plank_confusion_matrix.png

    core/squat_model/model/squat_stage_mlp.h5
    core/squat_model/model/squat_stage_mlp.tflite
    core/squat_model/model/meta.json
    core/squat_model/model/squat_stage_training_curve.png
    core/squat_model/model/squat_stage_confusion_matrix.png
    core/squat_model/model/squat_thresholds.json
"""

import os
import json
from pathlib import Path

import numpy as np
import pandas as pd

from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from sklearn.metrics import (
    classification_report,
    confusion_matrix,
    f1_score,
)

import matplotlib.pyplot as plt

import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers

os.environ["TF_CPP_MIN_LOG_LEVEL"] = "2"  # suppress TF warnings a bit


# -------------------------
# Path config
# -------------------------

THIS_DIR = Path(__file__).resolve().parent
PLANK_TRAIN_CSV = THIS_DIR / "plank_model" / "train.csv"
SQUAT_TRAIN_CSV = THIS_DIR / "squat_model" / "train.csv"

PLANK_MODEL_DIR = THIS_DIR / "plank_model" / "model"
SQUAT_MODEL_DIR = THIS_DIR / "squat_model" / "model"

PLANK_MODEL_DIR.mkdir(parents=True, exist_ok=True)
SQUAT_MODEL_DIR.mkdir(parents=True, exist_ok=True)


# -------------------------
# Utils: plotting
# -------------------------

def plot_training_history(history, title: str, save_path: Path | None = None):
    """Plot accuracy & loss vs epoch."""
    acc = history.history.get("accuracy", [])
    val_acc = history.history.get("val_accuracy", [])
    loss = history.history.get("loss", [])
    val_loss = history.history.get("val_loss", [])

    epochs = range(1, len(acc) + 1)

    fig, axs = plt.subplots(1, 2, figsize=(10, 4))
    fig.suptitle(title)

    # Accuracy
    axs[0].plot(epochs, acc, label="train acc")
    axs[0].plot(epochs, val_acc, label="val acc")
    axs[0].set_xlabel("Epoch")
    axs[0].set_ylabel("Accuracy")
    axs[0].legend()
    axs[0].grid(True, alpha=0.3)

    # Loss
    axs[1].plot(epochs, loss, label="train loss")
    axs[1].plot(epochs, val_loss, label="val loss")
    axs[1].set_xlabel("Epoch")
    axs[1].set_ylabel("Loss")
    axs[1].legend()
    axs[1].grid(True, alpha=0.3)

    plt.tight_layout()

    if save_path is not None:
        plt.savefig(save_path, dpi=150)
        print(f"[PLOT] Saved training curve to: {save_path}")

    # Kalau mau lihat interaktif, bisa aktifkan:
    # plt.show()
    plt.close(fig)


def plot_confusion_matrix(
    y_true,
    y_pred,
    class_names,
    title: str,
    save_path: Path | None = None,
):
    """Plot confusion matrix dengan matplotlib."""
    cm = confusion_matrix(y_true, y_pred)
    fig, ax = plt.subplots(figsize=(6, 5))
    im = ax.imshow(cm, interpolation="nearest", cmap="Blues")
    ax.figure.colorbar(im, ax=ax)

    ax.set(
        xticks=np.arange(len(class_names)),
        yticks=np.arange(len(class_names)),
        xticklabels=class_names,
        yticklabels=class_names,
        xlabel="Predicted label",
        ylabel="True label",
        title=title,
    )

    plt.setp(ax.get_xticklabels(), rotation=45, ha="right", rotation_mode="anchor")

    thresh = cm.max() / 2.0
    for i in range(cm.shape[0]):
        for j in range(cm.shape[1]):
            ax.text(
                j,
                i,
                format(cm[i, j], "d"),
                ha="center",
                va="center",
                color="white" if cm[i, j] > thresh else "black",
            )

    fig.tight_layout()
    if save_path is not None:
        plt.savefig(save_path, dpi=150)
        print(f"[PLOT] Saved confusion matrix to: {save_path}")

    # plt.show()
    plt.close(fig)


# -------------------------
# Plank feature engineering (dari train_plank_model2)
# -------------------------

def _compute_angle(ax, ay, bx, by, cx, cy):
    """
    Hitung sudut (derajat) di titik B dari segitiga A-B-C.
    Semua argumen boleh berupa array NumPy (vectorized).
    """
    v1x = ax - bx
    v1y = ay - by
    v2x = cx - bx
    v2y = cy - by

    dot = v1x * v2x + v1y * v2y
    norm1 = np.sqrt(v1x**2 + v1y**2) + 1e-6
    norm2 = np.sqrt(v2x**2 + v2y**2) + 1e-6

    # Pastikan dot / (norm1 * norm2) berada dalam rentang [-1.0, 1.0]
    cos_theta = np.clip(dot / (norm1 * norm2), -1.0, 1.0)
    angle = np.degrees(np.arccos(cos_theta))
    return angle


def add_plank_pose_features(df: pd.DataFrame) -> pd.DataFrame:
    """
    Ubah raw landmark -> fitur:
    - relative coordinate (translation invariant)
    - scaled (scale invariant)
    - angle-based features
    + normalisasi sederhana (rel coords / scale, angle / 180)
    """

    required_cols = [
        "left_shoulder_x", "left_shoulder_y",
        "right_shoulder_x", "right_shoulder_y",
        "left_hip_x", "left_hip_y",
        "right_hip_x", "right_hip_y",
        "left_knee_x", "left_knee_y",
        "right_knee_x", "right_knee_y",
        "left_ankle_x", "left_ankle_y",
        "right_ankle_x", "right_ankle_y",
    ]
    for c in required_cols:
        if c not in df.columns:
            # Kalau tidak lengkap, kembalikan df asli (fallback)
            print(f"[WARNING] Kolom '{c}' tidak ada. Mungkin dataset ini bukan untuk plank.")
            return df

    # 1) Titik referensi & scale (center + body size)
    lsx, lsy = df["left_shoulder_x"].values, df["left_shoulder_y"].values
    rsx, rsy = df["right_shoulder_x"].values, df["right_shoulder_y"].values
    lhx, lhy = df["left_hip_x"].values, df["left_hip_y"].values
    rhx, rhy = df["right_hip_x"].values, df["right_hip_y"].values
    lax, lay = df["left_ankle_x"].values, df["left_ankle_y"].values
    rax, ray = df["right_ankle_x"].values, df["right_ankle_y"].values

    shoulder_mid_x = (lsx + rsx) / 2.0
    shoulder_mid_y = (lsy + rsy) / 2.0
    hip_mid_x = (lhx + rhx) / 2.0
    hip_mid_y = (lhy + rhy) / 2.0
    ankle_mid_x = (lax + rax) / 2.0
    ankle_mid_y = (lay + ray) / 2.0

    # center tubuh = rata2 shoulder_mid & hip_mid
    center_x = (shoulder_mid_x + hip_mid_x) / 2.0
    center_y = (shoulder_mid_y + hip_mid_y) / 2.0

    # scale tubuh = jarak shoulder_mid ke ankle_mid (diagonal tubuh)
    dx = shoulder_mid_x - ankle_mid_x
    dy = shoulder_mid_y - ankle_mid_y
    body_scale = np.sqrt(dx**2 + dy**2) + 1e-6

    # 2) Relative + scaled coords untuk beberapa joint penting
    key_joints = [
        "left_shoulder", "right_shoulder",
        "left_hip", "right_hip",
        "left_knee", "right_knee",
        "left_ankle", "right_ankle",
    ]

    for joint in key_joints:
        jx = df[f"{joint}_x"].values
        jy = df[f"{joint}_y"].values

        x_rel = (jx - center_x) / body_scale
        y_rel = (jy - center_y) / body_scale

        df[f"{joint}_x_rel"] = x_rel
        df[f"{joint}_y_rel"] = y_rel

    # 3) Angle-based features (hip angle kiri & kanan, body_incline)
    # Sudut di hip kiri: shoulder_left - hip_left - ankle_left
    left_hip_angle = _compute_angle(
        df["left_shoulder_x"].values, df["left_shoulder_y"].values,
        df["left_hip_x"].values,      df["left_hip_y"].values,
        df["left_ankle_x"].values,    df["left_ankle_y"].values,
    )
    right_hip_angle = _compute_angle(
        df["right_shoulder_x"].values, df["right_shoulder_y"].values,
        df["right_hip_x"].values,      df["right_hip_y"].values,
        df["right_ankle_x"].values,    df["right_ankle_y"].values,
    )

    df["left_hip_angle_deg"] = left_hip_angle
    df["right_hip_angle_deg"] = right_hip_angle

    # Body incline angle: shoulder_mid - hip_mid - ankle_mid
    body_angle = _compute_angle(
        shoulder_mid_x, shoulder_mid_y,
        hip_mid_x,      hip_mid_y,
        ankle_mid_x,    ankle_mid_y,
    )
    df["body_angle_deg"] = body_angle

    # 4) Normalisasi sudut -> 0..1
    df["left_hip_angle_norm"] = df["left_hip_angle_deg"] / 180.0
    df["right_hip_angle_norm"] = df["right_hip_angle_deg"] / 180.0
    df["body_angle_norm"] = df["body_angle_deg"] / 180.0

    return df


# -------------------------
# Utils: data & model
# -------------------------

def build_mlp_classifier(input_dim: int, num_classes: int) -> keras.Model:
    """Simple, mobile-friendly MLP classifier untuk Pose Classification."""
    model = keras.Sequential(
        [
            layers.Input(shape=(input_dim,)),
            layers.Dense(64, activation="relu"),
            layers.Dropout(0.25),
            layers.Dense(32, activation="relu"),
            layers.Dropout(0.25),
            layers.Dense(num_classes, activation="softmax"),
        ]
    )

    model.compile(
        optimizer=keras.optimizers.Adam(learning_rate=1e-3),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )
    return model


def load_and_prepare(csv_path: Path, exercise_name: str):
    """Load CSV -> (df, X, y, feature_cols, label_encoder) dengan feature engineering opsional."""
    if not csv_path.exists():
        raise FileNotFoundError(f"CSV not found: {csv_path}")

    df = pd.read_csv(csv_path)

    if "label" not in df.columns:
        raise ValueError(f"'label' column not found in {csv_path}")

    # Buang kolom 'Unnamed' kalau ada
    df = df[[c for c in df.columns if not c.lower().startswith("unnamed")]]

    # 1) Feature engineering
    if exercise_name == "plank":
        # Gunakan feature engineering khusus plank
        df = add_plank_pose_features(df)

        # Pilih hanya kolom fitur engineered (bukan raw x,y)
        feature_cols = [
            c
            for c in df.columns
            if (
                c.endswith("_x_rel")
                or c.endswith("_y_rel")
                or c.endswith("_angle_norm")
            )
        ]
    else:
        # default: pakai semua fitur selain "label"
        feature_cols = [c for c in df.columns if c != "label"]

    if not feature_cols:
        raise ValueError("Tidak ada kolom fitur yang terdeteksi setelah feature engineering/selection.")

    # 2) Ambil X, y, encode label
    X = df[feature_cols].astype("float32").values
    y_str = df["label"].astype(str).values

    le = LabelEncoder()
    y = le.fit_transform(y_str)

    return df, X, y, feature_cols, le


def train_pose_classifier(
    csv_path: Path,
    model_dir: Path,
    keras_name: str,
    tflite_name: str,
    exercise_name: str,
    epochs: int = 80,
    batch_size: int = 64,
):
    """Training pose classifier (plank / squat_stage) + simpan model, meta, TFLite, dan plot."""
    print(f"\n=== Training {exercise_name.upper()} model ===")

    df, X, y, feature_cols, le = load_and_prepare(csv_path, exercise_name=exercise_name)

    num_classes = len(le.classes_)
    print(f"Num samples: {len(df)}, num features: {X.shape[1]}, num classes: {num_classes}")
    print(f"Classes: {list(le.classes_)}")

    X_train, X_val, y_train, y_val = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )

    model = build_mlp_classifier(input_dim=X.shape[1], num_classes=num_classes)

    callbacks = [
        keras.callbacks.EarlyStopping(
            monitor="val_accuracy", patience=10, restore_best_weights=True
        ),
        keras.callbacks.ReduceLROnPlateau(
            monitor="val_loss", factor=0.5, patience=5, min_lr=1e-5
        ),
    ]

    history = model.fit(
        X_train,
        y_train,
        validation_data=(X_val, y_val),
        epochs=epochs,
        batch_size=batch_size,
        verbose=1,
        callbacks=callbacks,
    )

    # --- Eval dasar ---
    val_loss, val_acc = model.evaluate(X_val, y_val, verbose=0)
    print(f"[{exercise_name}] Val accuracy: {val_acc:.4f}, Val loss: {val_loss:.4f}")

    # --- Prediksi & metrics tambahan ---
    y_val_pred_proba = model.predict(X_val, batch_size=batch_size, verbose=0)
    y_val_pred = np.argmax(y_val_pred_proba, axis=1)

    f1_w = f1_score(y_val, y_val_pred, average="weighted")
    f1_macro = f1_score(y_val, y_val_pred, average="macro")

    print(f"[{exercise_name}] F1-score (weighted): {f1_w:.4f}")
    print(f"[{exercise_name}] F1-score (macro):    {f1_macro:.4f}")
    print(f"[{exercise_name}] Classification report:\n")
    print(classification_report(y_val, y_val_pred, target_names=le.classes_, digits=4))

    # --- Plot training curve ---
    curve_path = model_dir / f"{exercise_name}_training_curve.png"
    plot_training_history(
        history,
        title=f"{exercise_name} - Training & Validation",
        save_path=curve_path,
    )

    # --- Plot confusion matrix ---
    cm_title = f"{exercise_name} - Confusion Matrix (val)"
    cm_path = model_dir / f"{exercise_name}_confusion_matrix.png"
    plot_confusion_matrix(
        y_val,
        y_val_pred,
        class_names=list(le.classes_),
        title=cm_title,
        save_path=cm_path,
    )

    # --- Save Keras model (.h5) ---
    keras_path = model_dir / keras_name
    model.save(keras_path)
    print(f"[{exercise_name}] Saved Keras model to: {keras_path}")

    # --- Export TFLite (dynamic range quantization) ---
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_model = converter.convert()
    tflite_path = model_dir / tflite_name
    with open(tflite_path, "wb") as f:
        f.write(tflite_model)
    print(f"[{exercise_name}] Saved TFLite model to: {tflite_path}")

    # --- Save meta (feature order + label mapping) ---
    label_mapping = {int(i): cls for i, cls in enumerate(le.classes_)}
    meta = {
        "feature_columns": feature_cols,
        "label_mapping": label_mapping,
    }
    meta_path = model_dir / "meta.json"
    with open(meta_path, "w", encoding="utf-8") as f:
        json.dump(meta, f, indent=2, ensure_ascii=False)

    print(f"[{exercise_name}] Saved meta to: {meta_path}")

    return df, model, meta


# -------------------------
# Squat thresholds (versi sederhana)
# -------------------------

def compute_squat_thresholds(df: pd.DataFrame) -> dict:
    """
    Hitung threshold biomekanik squat:
    - feet_ratio = jarak antar ankle / jarak antar shoulder
    - knee_ratio = jarak antar knee / jarak antar ankle

    Threshold diambil dari persentil [5%, 95%] dataset (diasumsikan mayoritas data benar).
    """
    required_cols = [
        "left_shoulder_x", "right_shoulder_x",
        "left_knee_x", "right_knee_x",
        "left_ankle_x", "right_ankle_x",
    ]
    for c in required_cols:
        if c not in df.columns:
            raise ValueError(f"Column '{c}' not found in squat train.csv")

    ls = df["left_shoulder_x"].values
    rs = df["right_shoulder_x"].values
    lk = df["left_knee_x"].values
    rk = df["right_knee_x"].values
    la = df["left_ankle_x"].values
    ra = df["right_ankle_x"].values

    shoulder_w = np.abs(rs - ls)
    feet_w = np.abs(ra - la)
    knee_w = np.abs(rk - lk)

    # Hindari div 0
    eps = 1e-6
    valid = (shoulder_w > eps) & (feet_w > eps)

    feet_ratio = feet_w[valid] / (shoulder_w[valid] + eps)
    knee_ratio = knee_w[valid] / (feet_w[valid] + eps)

    thresholds = {
        "feet_ratio_min": float(np.percentile(feet_ratio, 5)),
        "feet_ratio_max": float(np.percentile(feet_ratio, 95)),
        "knee_ratio_min": float(np.percentile(knee_ratio, 5)),
        "knee_ratio_max": float(np.percentile(knee_ratio, 95)),
    }
    print("\n[Squat] Computed thresholds:")
    for k, v in thresholds.items():
        print(f"  {k}: {v:.4f}")

    return thresholds


# -------------------------
# Main
# -------------------------

def main():
    # 1) Train Plank (menggunakan feature engineering khusus)
    train_pose_classifier(
        csv_path=PLANK_TRAIN_CSV,
        model_dir=PLANK_MODEL_DIR,
        keras_name="plank_mlp.h5",
        tflite_name="plank_mlp.tflite",
        exercise_name="plank",
    )

    # 2) Train Squat stage model (fitur generik: semua kolom numerik selain label)
    squat_df, _, _ = train_pose_classifier(
        csv_path=SQUAT_TRAIN_CSV,
        model_dir=SQUAT_MODEL_DIR,
        keras_name="squat_stage_mlp.h5",
        tflite_name="squat_stage_mlp.tflite",
        exercise_name="squat_stage",
    )

    # 3) Hitung dan simpan threshold squat (feet/knee)
    thresholds = compute_squat_thresholds(squat_df)
    thresholds_path = SQUAT_MODEL_DIR / "squat_thresholds.json"
    with open(thresholds_path, "w", encoding="utf-8") as f:
        json.dump(thresholds, f, indent=2)
    print(f"[Squat] Saved thresholds to: {thresholds_path}")


if __name__ == "__main__":
    main()