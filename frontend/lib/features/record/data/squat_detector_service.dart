import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// Service for detecting squats using pose estimation and ML classification
class SquatDetectorService {
  // ML Kit Pose Detector
  late PoseDetector _poseDetector;

  // TFLite Interpreter for squat stage classification
  Interpreter? _interpreter;

  // State
  bool _isInitialized = false;

  // Output
  Pose? _lastPose;
  String _currentState = 'none';
  double _downProb = 0.0;
  double _upProb = 0.0;
  int _repCount = 0;
  int _invalidRepCount = 0;
  bool _isLowerBodyVisible = false;

  // Callback for invalid rep detection
  Function()? onInvalidRep;

  // Form validation
  Map<String, double> _thresholds = {};
  String _feetStatus = 'unknown';
  String _kneeStatus = 'unknown';
  String _prevFeetStatus = 'unknown';
  String _prevKneeStatus = 'unknown';
  bool _hadIncorrectFormThisRep = false;

  bool get isInitialized => _isInitialized;
  Pose? get lastPose => _lastPose;
  String get currentState => _currentState;
  double get downProb => _downProb;
  double get upProb => _upProb;
  String get feetStatus => _feetStatus;
  String get kneeStatus => _kneeStatus;
  bool get isFormCorrect =>
      _feetStatus == 'correct' && _kneeStatus == 'correct';
  int get repCount => _repCount;
  int get invalidRepCount => _invalidRepCount;
  bool get isLowerBodyVisible => _isLowerBodyVisible;

  /// Reset the counter and state
  void resetCounter() {
    _repCount = 0;
    _invalidRepCount = 0;
    _currentState = 'none';
    _hadIncorrectFormThisRep = false;
    _prevFeetStatus = 'unknown';
    _prevKneeStatus = 'unknown';
  }

  /// Initialize the pose detector and ML model
  Future<void> initialize() async {
    try {
      // Initialize ML Kit Pose Detector
      final options = PoseDetectorOptions(
        model: PoseDetectionModel.base,
        mode: PoseDetectionMode.stream,
      );
      _poseDetector = PoseDetector(options: options);

      // Load TFLite model
      await _loadModel();

      // Load thresholds
      await _loadThresholds();

      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize SquatDetectorService: $e');
    }
  }

  /// Load the TFLite model for squat stage classification
  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/models/squat_stage_mlp.tflite',
      );
    } catch (e) {
      throw Exception('Failed to load TFLite model: $e');
    }
  }

  /// Load thresholds for form validation
  Future<void> _loadThresholds() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/models/squat_thresholds.json',
      );
      _thresholds = Map<String, double>.from(json.decode(jsonString));
    } catch (e) {
      _thresholds = {
        'feet_ratio_min': 0.4134821597055335,
        'feet_ratio_max': 1.564659821058367,
        'knee_ratio_min': 0.6782825087970797,
        'knee_ratio_max': 1.8640124560918636,
      };
    }
  }

  /// Detect squat from input image
  Future<void> detectSquat(InputImage inputImage) async {
    if (!_isInitialized || _interpreter == null) return;

    try {
      // Detect pose
      final poses = await _poseDetector.processImage(inputImage);
      if (poses.isEmpty) {
        _lastPose = null;
        return;
      }

      _lastPose = poses.first;

      // Prepare input and run model
      // ML Kit returns rotated coordinates, so swap width/height for normalization
      final rotatedSize = inputImage.metadata?.size != null
          ? Size(
              inputImage.metadata!.size.height,
              inputImage.metadata!.size.width,
            )
          : null;
      final input = _preparePoseInput(_lastPose!, rotatedSize);
      final output = _runInference(input);

      // Store probabilities
      _downProb = output[0];
      _upProb = output[1];

      // Check if lower body is visible
      _isLowerBodyVisible = _checkLowerBodyVisible(_lastPose!);

      // Analyze form to validate pose quality
      _analyzeForm(_lastPose!);

      // Counter state machine - only works if lower body is visible
      if (_isLowerBodyVisible) {
        _updateCounterState();
      }
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Prepare pose landmarks as input for the TFLite model
  List<double> _preparePoseInput(Pose pose, Size? imageSize) {
    final landmarkTypes = [
      PoseLandmarkType.nose,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.rightKnee,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightAnkle,
    ];

    final List<double> input = [];
    final width = imageSize?.width ?? 1.0;
    final height = imageSize?.height ?? 1.0;

    // Crop to center square (model trained on 480x480)
    final cropSize = min(width, height);
    final offsetX = (width - cropSize) / 2;
    final offsetY = (height - cropSize) / 2;

    for (final landmarkType in landmarkTypes) {
      final landmark = pose.landmarks[landmarkType];
      if (landmark != null) {
        // Adjust coordinates to cropped square space
        final croppedX = landmark.x - offsetX;
        final croppedY = landmark.y - offsetY;

        // Normalize by crop size and clamp to 0-1 range
        final normX = (croppedX / cropSize).clamp(0.0, 1.0);
        final normY = (croppedY / cropSize).clamp(0.0, 1.0);
        input.add(normX);
        input.add(normY);
        input.add(landmark.z);
        input.add(landmark.likelihood);
      } else {
        input.addAll([0.0, 0.0, 0.0, 0.0]);
      }
    }

    return input;
  }

  /// Run inference on the TFLite model
  List<double> _runInference(List<double> input) {
    try {
      final inputTensor = [input];
      final outputTensor = List.filled(1, List.filled(2, 0.0));
      _interpreter!.run(inputTensor, outputTensor);
      return outputTensor[0];
    } catch (e) {
      return [0.0, 1.0];
    }
  }

  /// Calculate 2D Euclidean distance between two landmarks
  double _distance2D(PoseLandmark p1, PoseLandmark p2) {
    return sqrt(pow(p2.x - p1.x, 2) + pow(p2.y - p1.y, 2));
  }

  /// Check if lower body (hips, knees, ankles) is properly visible
  bool _checkLowerBodyVisible(Pose pose) {
    const minConfidence = 0.5;

    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

    // Check if all landmarks exist and have sufficient confidence
    return leftHip != null &&
        leftHip.likelihood >= minConfidence &&
        rightHip != null &&
        rightHip.likelihood >= minConfidence &&
        leftKnee != null &&
        leftKnee.likelihood >= minConfidence &&
        rightKnee != null &&
        rightKnee.likelihood >= minConfidence &&
        leftAnkle != null &&
        leftAnkle.likelihood >= minConfidence &&
        rightAnkle != null &&
        rightAnkle.likelihood >= minConfidence;
  }

  /// Update counter state based on model predictions and form validation
  void _updateCounterState() {
    final modelPrediction = _downProb > _upProb ? 'down' : 'up';

    // State machine logic
    if (_currentState == 'none') {
      // Initial state: transition to 'down' if model predicts down
      if (modelPrediction == 'down') {
        _currentState = 'down';
        _hadIncorrectFormThisRep = false;
      }
    } else if (_currentState == 'down') {
      // Check if form changed from incorrect to correct (detection of bad form)
      if ((_prevFeetStatus != 'correct' && _feetStatus == 'correct') ||
          (_prevKneeStatus != 'correct' && _kneeStatus == 'correct')) {
        _hadIncorrectFormThisRep = true;
      }

      // In down state: transition to 'up' if model predicts up
      if (modelPrediction == 'up') {
        _currentState = 'up';
        _repCount++;
        // Track invalid rep if form was incorrect at any point during this rep
        if (_hadIncorrectFormThisRep) {
          _invalidRepCount++;
          onInvalidRep?.call();
        }
        // Reset flag for next rep
        _hadIncorrectFormThisRep = false;
      }
    } else if (_currentState == 'up') {
      // In up state: transition back to 'down' if model predicts down
      if (modelPrediction == 'down') {
        _currentState = 'down';
        _hadIncorrectFormThisRep = false;
      }
    }

    // Update previous status for next frame
    _prevFeetStatus = _feetStatus;
    _prevKneeStatus = _kneeStatus;
  }

  /// Analyze squat form based on feet and knee width ratios
  void _analyzeForm(Pose pose) {
    // Get required landmarks
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

    // Check if all landmarks exist
    if (leftShoulder == null ||
        rightShoulder == null ||
        leftKnee == null ||
        rightKnee == null ||
        leftAnkle == null ||
        rightAnkle == null) {
      _feetStatus = 'unknown';
      _kneeStatus = 'unknown';
      return;
    }

    // Calculate widths using 2D distance
    final shoulderWidth = _distance2D(leftShoulder, rightShoulder);
    final feetWidth = _distance2D(leftAnkle, rightAnkle);
    final kneeWidth = _distance2D(leftKnee, rightKnee);

    const eps = 1e-6;
    if (shoulderWidth < eps || feetWidth < eps) {
      _feetStatus = 'unknown';
      _kneeStatus = 'unknown';
      return;
    }

    // Calculate ratios
    final feetRatio = feetWidth / (shoulderWidth + eps);
    final kneeRatio = kneeWidth / (feetWidth + eps);

    // Get threshold values
    final feetRatioMin = _thresholds['feet_ratio_min']!;
    final feetRatioMax = _thresholds['feet_ratio_max']!;
    final kneeRatioMin = _thresholds['knee_ratio_min']!;
    final kneeRatioMax = _thresholds['knee_ratio_max']!;

    // FEET status determination
    if (feetRatio < feetRatioMin) {
      _feetStatus = 'too_close';
    } else if (feetRatio > feetRatioMax) {
      _feetStatus = 'too_wide';
    } else {
      _feetStatus = 'correct';
    }

    // KNEE status determination
    if (kneeRatio < kneeRatioMin) {
      _kneeStatus = 'caving_in';
    } else if (kneeRatio > kneeRatioMax) {
      _kneeStatus = 'too_wide';
    } else {
      _kneeStatus = 'correct';
    }
  }

  /// Dispose resources
  void dispose() {
    _poseDetector.close();
    _interpreter?.close();
  }
}
