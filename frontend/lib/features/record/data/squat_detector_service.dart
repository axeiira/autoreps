import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// Service for detecting squats using pose estimation and a TFLite model
class SquatDetectorService {
  Interpreter? _interpreter;
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.accurate,
    ),
  );

  bool _isInitialized = false;
  int _repCount = 0;
  bool _isSquatting = false;
  
  bool get isInitialized => _isInitialized;
  int get repCount => _repCount;
  bool get isSquatting => _isSquatting;

  /// Initialize the TFLite model
  Future<void> initialize() async {
    try {
      _interpreter = await Interpreter.fromAsset('lib/features/record/data/LR_model.tflite');
      _isInitialized = true;
      print('✓ Squat detector initialized successfully');
    } catch (e) {
      print('✗ Failed to load TFLite model: $e');
      rethrow;
    }
  }

  /// Extract features from pose landmarks for the model
  /// This converts pose keypoints into a feature vector expected by the LR model
  /// Model expects 36 features: 12 landmarks × 3 coordinates (x, y, z)
  List<double> _extractFeatures(Pose pose) {
    final List<double> features = [];
    
    // Extract key landmarks for squat detection
    // Using 12 important landmarks: shoulders, hips, knees, ankles, elbows, wrists
    final keyLandmarks = [
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.leftWrist,
      PoseLandmarkType.rightWrist,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.rightKnee,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightAnkle,
    ];
    
    for (final landmarkType in keyLandmarks) {
      final landmark = pose.landmarks[landmarkType];
      if (landmark != null) {
        features.add(landmark.x);
        features.add(landmark.y);
        features.add(landmark.z);
      } else {
        // If landmark is missing, add zeros
        features.addAll([0.0, 0.0, 0.0]);
      }
    }
    
    // Should have exactly 36 features (12 landmarks × 3 coordinates)
    assert(features.length == 36, 'Feature count mismatch: expected 36, got ${features.length}');
    
    return features;
  }

  /// Process a camera frame and detect squat
  Future<bool> detectSquat(InputImage inputImage) async {
    if (!_isInitialized || _interpreter == null) {
      throw Exception('SquatDetectorService not initialized');
    }

    try {
      // Step 1: Detect pose using ML Kit
      final List<Pose> poses = await _poseDetector.processImage(inputImage);
      
      if (poses.isEmpty) {
        // No person detected
        return false;
      }

      // Use the first detected pose
      final pose = poses.first;
      
      // Step 2: Extract features from pose landmarks
      final features = _extractFeatures(pose);
      
      // Step 3: Prepare input for TFLite model
      // Reshape to [1, numFeatures]
      final input = [features];
      
      // Step 4: Prepare output buffer
      final output = List.filled(1, 0.0).reshape([1, 1]);
      
      // Step 5: Run inference
      _interpreter!.run(input, output);
      
      // Step 6: Get prediction (probability of squat)
      final prediction = output[0][0] as double;
      
      // Step 7: Classify as squat if probability > 0.5
      final isCurrentlySquatting = prediction > 0.5;
      
      // Step 8: Count reps (transition from standing to squatting)
      if (isCurrentlySquatting && !_isSquatting) {
        // Just started squatting
        _repCount++;
      }
      
      _isSquatting = isCurrentlySquatting;
      
      return isCurrentlySquatting;
    } catch (e) {
      print('Error during squat detection: $e');
      rethrow;
    }
  }

  /// Reset the rep counter
  void resetReps() {
    _repCount = 0;
    _isSquatting = false;
  }

  /// Clean up resources
  void dispose() {
    _interpreter?.close();
    _poseDetector.close();
    _isInitialized = false;
  }
}
