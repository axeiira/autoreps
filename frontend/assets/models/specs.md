Input: 36 float values (9 landmarks × 4 coordinates each)

[nose_x, nose_y, nose_z, nose_visibility,
 left_shoulder_x, left_shoulder_y, left_shoulder_z, left_shoulder_visibility,
 right_shoulder_x, right_shoulder_y, right_shoulder_z, right_shoulder_visibility,
 left_hip_x, left_hip_y, left_hip_z, left_hip_visibility,
 right_hip_x, right_hip_y, right_hip_z, right_hip_visibility,
 left_knee_x, left_knee_y, left_knee_z, left_knee_visibility,
 right_knee_x, right_knee_y, right_knee_z, right_knee_visibility,
 left_ankle_x, left_ankle_y, left_ankle_z, left_ankle_visibility,
 right_ankle_x, right_ankle_y, right_ankle_z, right_ankle_visibility]

Output: 2 probabilities [down_prob, up_prob]
    Index 0 = "down" (squatting position)
    Index 1 = "up" (standing position)