#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Realtime demo (480p, NO FRAME SKIP) dengan TFLite:

- Pose: MediaPipe Pose (model_complexity=0 / lite)
- Model ML: TFLite (plank_mlp.tflite, squat_stage_mlp.tflite)
- Plank:
    - Menggunakan fitur engineered (relative coords + angle) yang sama seperti training.
    - Klasifikasi C / H / L + status FORM BENAR / SALAH.
- Squat:
    - Klasifikasi stage (down / up).
    - FEET & KNEE form (correct / terlalu rapat / terlalu lebar) dari squat_thresholds.json.
    - Count hanya bertambah jika:
        - lower body terlihat,
        - transisi down -> up,
        - posisi up benar-benar berdiri,
        - FEET dan KNEE = correct.
- Overlay:
    - Skeleton (bisa toggle),
    - FPS,
    - Mode, label, count, FEET/KNEE status, form status.
"""

import json
import math
import time
from pathlib import Path
from typing import List, Dict, Tuple, Optional

import cv2
import numpy as np
import mediapipe as mp
import tensorflow as tf

THIS_DIR = Path(__file__).resolve().parent

# -------------------------- PATH MODEL & META -------------------------- #

PLANK_TFLITE = THIS_DIR / "plank_model" / "model" / "plank_mlp.tflite"
# SESUAIKAN kalau meta kamu namanya beda, misalnya "meta_plank_new_V2.json"
PLANK_META   = THIS_DIR / "plank_model" / "model" / "meta.json"

SQUAT_TFLITE = THIS_DIR / "squat_model" / "model" / "squat_stage_mlp.tflite"
SQUAT_META   = THIS_DIR / "squat_model" / "model" / "meta.json"
SQUAT_THRESHOLDS = THIS_DIR / "squat_model" / "model" / "squat_thresholds.json"

# Label stage squat (untuk counting)
SQUAT_STAGE_DOWN_LABELS = {"down", "bottom"}
SQUAT_STAGE_UP_LABELS   = {"up", "stand", "top"}

mp_drawing = mp.solutions.drawing_utils
mp_pose = mp.solutions.pose

JOINT_NAME_TO_MP = {
    "nose": mp_pose.PoseLandmark.NOSE,
    "left_shoulder": mp_pose.PoseLandmark.LEFT_SHOULDER,
    "right_shoulder": mp_pose.PoseLandmark.RIGHT_SHOULDER,
    "left_hip": mp_pose.PoseLandmark.LEFT_HIP,
    "right_hip": mp_pose.PoseLandmark.RIGHT_HIP,
    "left_knee": mp_pose.PoseLandmark.LEFT_KNEE,
    "right_knee": mp_pose.PoseLandmark.RIGHT_KNEE,
    "left_ankle": mp_pose.PoseLandmark.LEFT_ANKLE,
    "right_ankle": mp_pose.PoseLandmark.RIGHT_ANKLE,
}


# -------------------------- DRAW HELPERS -------------------------- #

def draw_text_with_outline(
    frame,
    text: str,
    org: Tuple[int, int],
    font_scale: float,
    color: Tuple[int, int, int],
    thickness: int = 2,
):
    """Tulis teks dengan outline hitam (tanpa background box)."""
    cv2.putText(
        frame,
        text,
        org,
        cv2.FONT_HERSHEY_SIMPLEX,
        font_scale,
        (0, 0, 0),
        thickness + 2,
        cv2.LINE_AA,
    )
    cv2.putText(
        frame,
        text,
        org,
        cv2.FONT_HERSHEY_SIMPLEX,
        font_scale,
        color,
        thickness,
        cv2.LINE_AA,
    )


# -------------------------- TFLITE CLASSIFIER -------------------------- #

class TFLitePoseClassifier:
    """
    Classifier pose menggunakan TFLite model (.tflite) + meta.json.

    - Untuk squat_stage: pakai fitur generik (raw x,y,z,visibility) dari landmark.
    - Untuk plank      : pakai fitur engineered seperti di training:
                         *_x_rel, *_y_rel, *_angle_norm.
    """

    def __init__(self, tflite_path: Path, meta_path: Path, exercise_name: str):
        if not tflite_path.exists():
            raise FileNotFoundError(f"TFLite model not found: {tflite_path}")
        if not meta_path.exists():
            raise FileNotFoundError(f"Meta file not found: {meta_path}")

        self.exercise_name = exercise_name
        print(f"[{exercise_name}] Loading TFLite model: {tflite_path}")

        self.interpreter = tf.lite.Interpreter(model_path=str(tflite_path))
        self.interpreter.allocate_tensors()
        self.input_details = self.interpreter.get_input_details()
        self.output_details = self.interpreter.get_output_details()

        with open(meta_path, "r", encoding="utf-8") as f:
            meta = json.load(f)

        self.feature_columns: List[str] = meta["feature_columns"]
        self.label_mapping: Dict[int, str] = {
            int(k): v for k, v in meta["label_mapping"].items()
        }

        print(f"[{exercise_name}] Feature columns: {len(self.feature_columns)}")
        print(f"[{exercise_name}] Labels: {list(self.label_mapping.values())}")

        self.is_plank = (self.exercise_name == "plank")

        if self.is_plank:
            self._init_plank_feature_mapping()
        else:
            self._init_generic_feature_mapping()

    # ---------- GENERIC (untuk squat_stage) ---------- #

    def _init_generic_feature_mapping(self):
        """
        Buat mapping dari nama kolom -> (index landmark, kode koordinat)
        coord_code: 0=x, 1=y, 2=z, 3=visibility
        """
        self.feature_specs: List[Tuple[Optional[int], int]] = []
        for col in self.feature_columns:
            try:
                joint_name, coord = col.rsplit("_", 1)
            except ValueError:
                self.feature_specs.append((None, -1))
                continue

            lm_enum = JOINT_NAME_TO_MP.get(joint_name)
            if lm_enum is None:
                self.feature_specs.append((None, -1))
                continue

            coord_map = {"x": 0, "y": 1, "z": 2, "v": 3, "visibility": 3}
            coord_code = coord_map.get(coord, -1)
            self.feature_specs.append((lm_enum.value, coord_code))

    def _build_generic_feature_vector(self, pose_landmarks):
        if pose_landmarks is None:
            return None

        features = []
        for lm_idx, coord_code in self.feature_specs:
            if lm_idx is None or coord_code < 0:
                features.append(0.0)
                continue

            lm = pose_landmarks.landmark[lm_idx]
            if coord_code == 0:
                val = lm.x
            elif coord_code == 1:
                val = lm.y
            elif coord_code == 2:
                val = lm.z
            else:
                val = lm.visibility

            features.append(float(val))

        x = np.array(features, dtype="float32").reshape(1, -1)
        return x

    # ---------- PLANK (fitur engineered) ---------- #

    def _init_plank_feature_mapping(self):
        """
        Mapping urutan feature plank berdasarkan meta["feature_columns"].
        Kita bedakan:
        - *_x_rel, *_y_rel  -> rel coord feature
        - left_hip_angle_norm, right_hip_angle_norm, body_angle_norm -> angle feature
        """
        self.plank_feature_layout = []  # list of (kind, joint, axis/None)

        for col in self.feature_columns:
            if col.endswith("_x_rel"):
                joint = col[: -len("_x_rel")]
                self.plank_feature_layout.append(("rel", joint, "x"))
            elif col.endswith("_y_rel"):
                joint = col[: -len("_y_rel")]
                self.plank_feature_layout.append(("rel", joint, "y"))
            elif col == "left_hip_angle_norm":
                self.plank_feature_layout.append(("angle", "left_hip", None))
            elif col == "right_hip_angle_norm":
                self.plank_feature_layout.append(("angle", "right_hip", None))
            elif col == "body_angle_norm":
                self.plank_feature_layout.append(("angle", "body", None))
            else:
                # fitur lain yang mungkin ada, tapi tidak kita pakai -> isi 0 saja
                self.plank_feature_layout.append(("zero", None, None))

    @staticmethod
    def _angle_deg(ax, ay, bx, by, cx, cy) -> float:
        """Sudut (derajat) di titik B dari A-B-C."""
        v1x, v1y = ax - bx, ay - by
        v2x, v2y = cx - bx, cy - by
        dot = v1x * v2x + v1y * v2y
        n1 = math.sqrt(v1x * v1x + v1y * v1y) + 1e-6
        n2 = math.sqrt(v2x * v2x + v2y * v2y) + 1e-6
        cosang = max(-1.0, min(1.0, dot / (n1 * n2)))
        return math.degrees(math.acos(cosang))

    def _build_plank_feature_vector(self, pose_landmarks):
        """
        Replikasi logika add_plank_pose_features() tapi untuk 1 frame.
        """
        if pose_landmarks is None:
            return None

        lms = pose_landmarks.landmark

        def get_xy(name: str):
            idx = JOINT_NAME_TO_MP[name].value
            p = lms[idx]
            return p.x, p.y

        # Joint utama
        lsx, lsy = get_xy("left_shoulder")
        rsx, rsy = get_xy("right_shoulder")
        lhx, lhy = get_xy("left_hip")
        rhx, rhy = get_xy("right_hip")
        lkx, lky = get_xy("left_knee")
        rkx, rky = get_xy("right_knee")
        lax, lay = get_xy("left_ankle")
        rax, ray = get_xy("right_ankle")

        # 1) shoulder_mid, hip_mid, ankle_mid
        shoulder_mid_x = (lsx + rsx) / 2.0
        shoulder_mid_y = (lsy + rsy) / 2.0
        hip_mid_x = (lhx + rhx) / 2.0
        hip_mid_y = (lhy + rhy) / 2.0
        ankle_mid_x = (lax + rax) / 2.0
        ankle_mid_y = (lay + ray) / 2.0

        # center & body_scale
        center_x = (shoulder_mid_x + hip_mid_x) / 2.0
        center_y = (shoulder_mid_y + hip_mid_y) / 2.0

        dx = shoulder_mid_x - ankle_mid_x
        dy = shoulder_mid_y - ankle_mid_y
        body_scale = math.sqrt(dx * dx + dy * dy) + 1e-6

        # 2) Relative coords (x_rel, y_rel) untuk joint-joint kunci
        joints = {
            "left_shoulder": (lsx, lsy),
            "right_shoulder": (rsx, rsy),
            "left_hip": (lhx, lhy),
            "right_hip": (rhx, rhy),
            "left_knee": (lkx, lky),
            "right_knee": (rkx, rky),
            "left_ankle": (lax, lay),
            "right_ankle": (rax, ray),
        }

        rel = {}
        for name, (jx, jy) in joints.items():
            rel_x = (jx - center_x) / body_scale
            rel_y = (jy - center_y) / body_scale
            rel[name] = {"x": rel_x, "y": rel_y}

        # 3) Angle-based features
        left_hip_angle_deg = self._angle_deg(lsx, lsy, lhx, lhy, lax, lay)
        right_hip_angle_deg = self._angle_deg(rsx, rsy, rhx, rhy, rax, ray)
        body_angle_deg = self._angle_deg(
            shoulder_mid_x, shoulder_mid_y,
            hip_mid_x, hip_mid_y,
            ankle_mid_x, ankle_mid_y,
        )

        left_hip_angle_norm = left_hip_angle_deg / 180.0
        right_hip_angle_norm = right_hip_angle_deg / 180.0
        body_angle_norm = body_angle_deg / 180.0

        # 4) Susun fitur sesuai meta["feature_columns"]
        features = []
        for kind, joint, axis in self.plank_feature_layout:
            if kind == "rel":
                val = rel.get(joint, {"x": 0.0, "y": 0.0})[axis]
                features.append(float(val))
            elif kind == "angle":
                if joint == "left_hip":
                    features.append(float(left_hip_angle_norm))
                elif joint == "right_hip":
                    features.append(float(right_hip_angle_norm))
                elif joint == "body":
                    features.append(float(body_angle_norm))
                else:
                    features.append(0.0)
            else:
                features.append(0.0)

        x = np.array(features, dtype="float32").reshape(1, -1)
        return x

    # ---------- COMMON PREDICT ---------- #

    def _build_feature_vector(self, pose_landmarks):
        if self.is_plank:
            return self._build_plank_feature_vector(pose_landmarks)
        else:
            return self._build_generic_feature_vector(pose_landmarks)

    def predict(self, pose_landmarks):
        """Return: (label_string or None, prob_max, probs or None)."""
        x = self._build_feature_vector(pose_landmarks)
        if x is None:
            return None, 0.0, None

        input_index = self.input_details[0]["index"]
        self.interpreter.set_tensor(input_index, x)
        self.interpreter.invoke()
        output_index = self.output_details[0]["index"]
        probs = self.interpreter.get_tensor(output_index)[0]

        idx = int(np.argmax(probs))
        label = self.label_mapping.get(idx, f"class_{idx}")
        prob = float(probs[idx])
        return label, prob, probs


# -------------------------- SQUAT GEOMETRY & FORM -------------------------- #

def lower_body_visible(pose_landmarks, min_visibility: float = 0.6) -> bool:
    """True jika hip, knee, ankle kiri & kanan terlihat cukup jelas."""
    if pose_landmarks is None:
        return False
    idxs = [
        mp_pose.PoseLandmark.LEFT_HIP.value,
        mp_pose.PoseLandmark.RIGHT_HIP.value,
        mp_pose.PoseLandmark.LEFT_KNEE.value,
        mp_pose.PoseLandmark.RIGHT_KNEE.value,
        mp_pose.PoseLandmark.LEFT_ANKLE.value,
        mp_pose.PoseLandmark.RIGHT_ANKLE.value,
    ]
    for i in idxs:
        if pose_landmarks.landmark[i].visibility < min_visibility:
            return False
    return True


def knee_angle(hip, knee, ankle) -> float:
    """Sudut lutut (derajat) antara segmen hip-knee dan ankle-knee."""
    v1x, v1y = hip.x - knee.x, hip.y - knee.y
    v2x, v2y = ankle.x - knee.x, ankle.y - knee.y
    dot = v1x * v2x + v1y * v2y
    n1 = math.sqrt(v1x * v1x + v1y * v1y)
    n2 = math.sqrt(v2x * v2x + v2y * v2y)
    if n1 * n2 < 1e-6:
        return 180.0
    cosang = max(-1.0, min(1.0, dot / (n1 * n2)))
    return math.degrees(math.acos(cosang))


def is_standing_pose(pose_landmarks, knee_angle_min: float = 155.0) -> bool:
    """
    Kasar: true kalau kedua kaki relatif lurus (lutut > knee_angle_min)
    dan urutan vertikal hip > knee > ankle (dari atas ke bawah).
    """
    if pose_landmarks is None:
        return False
    try:
        lh = pose_landmarks.landmark[mp_pose.PoseLandmark.LEFT_HIP.value]
        rh = pose_landmarks.landmark[mp_pose.PoseLandmark.RIGHT_HIP.value]
        lk = pose_landmarks.landmark[mp_pose.PoseLandmark.LEFT_KNEE.value]
        rk = pose_landmarks.landmark[mp_pose.PoseLandmark.RIGHT_KNEE.value]
        la = pose_landmarks.landmark[mp_pose.PoseLandmark.LEFT_ANKLE.value]
        ra = pose_landmarks.landmark[mp_pose.PoseLandmark.RIGHT_ANKLE.value]
    except IndexError:
        return False

    # y makin besar = makin ke bawah
    if not (lh.y < lk.y < la.y and rh.y < rk.y < ra.y):
        return False

    ang_l = knee_angle(lh, lk, la)
    ang_r = knee_angle(rh, rk, ra)
    if ang_l < knee_angle_min or ang_r < knee_angle_min:
        return False

    return True


def analyze_squat_feet_knee(pose_landmarks, thresholds: dict):
    """
    FEET & KNEE status terpisah:
    - feet_status: 'correct' / 'terlalu rapat' / 'terlalu lebar' / 'unknown'
    - knee_status: 'correct' / 'terlalu rapat' / 'terlalu lebar' / 'unknown'

    Menggunakan jarak 2D (x,y) untuk konsisten dengan perhitungan threshold training.
    """
    if pose_landmarks is None:
        return "unknown", "unknown"

    try:
        ls = pose_landmarks.landmark[mp_pose.PoseLandmark.LEFT_SHOULDER.value]
        rs = pose_landmarks.landmark[mp_pose.PoseLandmark.RIGHT_SHOULDER.value]
        lk = pose_landmarks.landmark[mp_pose.PoseLandmark.LEFT_KNEE.value]
        rk = pose_landmarks.landmark[mp_pose.PoseLandmark.RIGHT_KNEE.value]
        la = pose_landmarks.landmark[mp_pose.PoseLandmark.LEFT_ANKLE.value]
        ra = pose_landmarks.landmark[mp_pose.PoseLandmark.RIGHT_ANKLE.value]
    except IndexError:
        return "unknown", "unknown"

    def dist_2d(p1, p2):
        return math.sqrt((p2.x - p1.x) ** 2 + (p2.y - p1.y) ** 2)

    shoulder_w = dist_2d(ls, rs)
    feet_w = dist_2d(la, ra)
    knee_w = dist_2d(lk, rk)

    eps = 1e-6
    if shoulder_w < eps or feet_w < eps:
        return "unknown", "unknown"

    feet_ratio = feet_w / (shoulder_w + eps)
    knee_ratio = knee_w / (feet_w + eps)

    try:
        fmin = thresholds["feet_ratio_min"]
        fmax = thresholds["feet_ratio_max"]
        kmin = thresholds["knee_ratio_min"]
        kmax = thresholds["knee_ratio_max"]
    except KeyError:
        return "unknown", "unknown"

    # FEET
    if feet_ratio < fmin:
        feet_status = "terlalu rapat"
    elif feet_ratio > fmax:
        feet_status = "terlalu lebar"
    else:
        feet_status = "correct"

    # KNEE
    if knee_ratio < kmin:
        knee_status = "terlalu rapat"
    elif knee_ratio > kmax:
        knee_status = "terlalu lebar"
    else:
        knee_status = "correct"

    return feet_status, knee_status


# -------------------------- MAIN LOOP -------------------------- #

def main():
    plank_cls = TFLitePoseClassifier(PLANK_TFLITE, PLANK_META, "plank")
    squat_cls = TFLitePoseClassifier(SQUAT_TFLITE, SQUAT_META, "squat_stage")

    if not SQUAT_THRESHOLDS.exists():
        raise FileNotFoundError(f"Squat thresholds not found: {SQUAT_THRESHOLDS}")
    with open(SQUAT_THRESHOLDS, "r", encoding="utf-8") as f:
        squat_thresholds = json.load(f)

    cap = cv2.VideoCapture(2)
    if not cap.isOpened():
        raise RuntimeError("Tidak bisa membuka webcam (device 0)")

    cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)

    current_mode = "plank"  # "plank" / "squat"
    draw_skeleton = True

    prev_time = time.time()
    fps = 0.0

    squat_count = 0
    squat_state = "none"  # "none" / "up" / "down"

    print("=== Realtime demo (TFLite, 480p, no frame skip) ===")
    print("Tombol: 'p' = Plank, 's' = Squat, 'd' = toggle skeleton, 'q' = quit")

    with mp_pose.Pose(
        min_detection_confidence=0.5,
        min_tracking_confidence=0.5,
        model_complexity=0,
    ) as pose:
        while True:
            ret, frame = cap.read()
            if not ret:
                print("Frame tidak terbaca, stop.")
                break

            now = time.time()
            dt = now - prev_time
            if dt > 0:
                fps = 1.0 / dt
            prev_time = now

            frame = cv2.flip(frame, 1)
            image_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            image_rgb.flags.writeable = False
            results = pose.process(image_rgb)
            image_rgb.flags.writeable = True

            pose_landmarks = results.pose_landmarks

            if draw_skeleton and pose_landmarks:
                mp_drawing.draw_landmarks(
                    frame,
                    pose_landmarks,
                    mp_pose.POSE_CONNECTIONS,
                    landmark_drawing_spec=mp_drawing.DrawingSpec(
                        thickness=2, circle_radius=2
                    ),
                    connection_drawing_spec=mp_drawing.DrawingSpec(thickness=1),
                )

            # ====== MODE PLANK ======
            if current_mode == "plank":
                mode_text = "MODE: PLANK"
                label, prob, _ = plank_cls.predict(pose_landmarks)

                if label is None:
                    text_main = "Plank: pose tidak terdeteksi"
                    form_text = ""
                else:
                    label_clean = label.strip().upper()
                    # HANYA C yang dianggap FORM BENAR
                    is_correct = (label_clean == "C")
                    form_status = "FORM BENAR" if is_correct else "FORM SALAH"
                    text_main = f"Plank: {label} ({prob:.2f})"
                    form_text = form_status

                count_line = ""
                feet_line = ""
                knee_line = ""

            # ====== MODE SQUAT ======
            else:
                mode_text = "MODE: SQUAT"
                label, prob, _ = squat_cls.predict(pose_landmarks)
                lower_vis = lower_body_visible(pose_landmarks, min_visibility=0.6)
                standing_now = is_standing_pose(pose_landmarks)

                if label is None or not lower_vis:
                    squat_stage = "unknown"
                    text_main = "Squat: pose tidak jelas / kaki tidak terlihat"
                else:
                    squat_stage = label.lower()
                    text_main = f"Squat stage: {label} ({prob:.2f})"

                feet_status, knee_status = analyze_squat_feet_knee(
                    pose_landmarks, squat_thresholds
                )

                # FORM BENAR hanya jika BOTH feet & knee correct
                if feet_status == "correct" and knee_status == "correct":
                    form_text = "FORM BENAR"
                    form_correct_flag = True
                elif feet_status == "unknown" and knee_status == "unknown":
                    form_text = ""
                    form_correct_flag = False
                else:
                    form_text = "FORM SALAH"
                    form_correct_flag = False

                # --------- COUNT: perlu lower_body, transisi DOWN->UP, standing, dan FORM BENAR --------- #
                if not lower_vis:
                    squat_state = "none"
                else:
                    is_down = any(s in squat_stage for s in SQUAT_STAGE_DOWN_LABELS)
                    is_up = any(s in squat_stage for s in SQUAT_STAGE_UP_LABELS) and standing_now

                    if is_down and squat_state != "down":
                        squat_state = "down"
                    elif (
                        is_up
                        and squat_state == "down"
                        and form_correct_flag  # HANYA kalau knee & feet correct
                    ):
                        squat_count += 1
                        squat_state = "up"
                # ----------------------------------------------------------------------------------------- #

                count_line = f"COUNT: {squat_count}, {label if label else 'unknown'}, {prob:.2f}"
                feet_line = f"FEET: {feet_status}"
                knee_line = f"KNEE: {knee_status}"

            # -------------------------- OVERLAY TEKS -------------------------- #
            h, w, _ = frame.shape
            fps_text = f"FPS: {fps:.1f}"

            draw_text_with_outline(frame, mode_text, (10, 30), 0.8, (0, 255, 255))
            draw_text_with_outline(frame, text_main, (10, 60), 0.7, (255, 255, 255))

            if current_mode == "plank":
                if form_text:
                    draw_text_with_outline(frame, form_text, (10, 90), 0.7, (0, 255, 0))
            else:
                if count_line:
                    draw_text_with_outline(frame, count_line, (10, 90), 0.7, (255, 255, 255))
                if feet_line:
                    draw_text_with_outline(frame, feet_line, (10, 120), 0.7, (0, 255, 0))
                if knee_line:
                    draw_text_with_outline(frame, knee_line, (10, 150), 0.7, (0, 255, 0))
                if form_text:
                    draw_text_with_outline(frame, form_text, (10, 180), 0.7, (0, 255, 255))

            draw_text_with_outline(frame, fps_text, (w - 160, 30), 0.7, (255, 255, 255))

            cv2.imshow("Exercise Correction (TFLite, 480p)", frame)

            key = cv2.waitKey(1) & 0xFF
            if key == ord("q"):
                break
            elif key == ord("p"):
                current_mode = "plank"
            elif key == ord("s"):
                current_mode = "squat"
            elif key == ord("d"):
                draw_skeleton = not draw_skeleton

    cap.release()
    cv2.destroyAllWindows()


if __name__ == "__main__":
    main()
