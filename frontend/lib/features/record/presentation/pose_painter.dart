import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Custom painter to draw pose landmarks and skeleton on camera preview
class PosePainter extends CustomPainter {
  final Pose? pose;
  final Size imageSize;

  PosePainter({required this.pose, required this.imageSize});

  @override
  void paint(Canvas canvas, Size size) {
    if (pose == null) return;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 4.0
      ..color = Colors.green;

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.greenAccent;

    // Draw landmarks
    pose!.landmarks.forEach((type, landmark) {
      final x = landmark.x * size.width / imageSize.width;
      final y = landmark.y * size.height / imageSize.height;
      canvas.drawCircle(Offset(x, y), 8, paint);
    });

    // Draw skeleton connections
    _drawLine(
      canvas,
      size,
      linePaint,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
    );
    _drawLine(
      canvas,
      size,
      linePaint,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.leftHip,
    );
    _drawLine(
      canvas,
      size,
      linePaint,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.rightHip,
    );
    _drawLine(
      canvas,
      size,
      linePaint,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
    );
    _drawLine(
      canvas,
      size,
      linePaint,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.leftElbow,
    );
    _drawLine(
      canvas,
      size,
      linePaint,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.leftWrist,
    );
    _drawLine(
      canvas,
      size,
      linePaint,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.rightElbow,
    );
    _drawLine(
      canvas,
      size,
      linePaint,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.rightWrist,
    );
    _drawLine(
      canvas,
      size,
      linePaint,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.leftKnee,
    );
    _drawLine(
      canvas,
      size,
      linePaint,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.leftAnkle,
    );
    _drawLine(
      canvas,
      size,
      linePaint,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.rightKnee,
    );
    _drawLine(
      canvas,
      size,
      linePaint,
      PoseLandmarkType.rightKnee,
      PoseLandmarkType.rightAnkle,
    );
  }

  void _drawLine(
    Canvas canvas,
    Size size,
    Paint paint,
    PoseLandmarkType from,
    PoseLandmarkType to,
  ) {
    final fromLandmark = pose!.landmarks[from];
    final toLandmark = pose!.landmarks[to];

    if (fromLandmark == null || toLandmark == null) return;

    final startX = fromLandmark.x * size.width / imageSize.width;
    final startY = fromLandmark.y * size.height / imageSize.height;
    final endX = toLandmark.x * size.width / imageSize.width;
    final endY = toLandmark.y * size.height / imageSize.height;

    canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.pose != pose;
  }
}
