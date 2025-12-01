// ignore_for_file: use_build_context_synchronously

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_autoreps/widgets/app_scaffold.dart';
import 'package:flutter_autoreps/features/record/data/squat_detector_service.dart';
import 'package:flutter_autoreps/features/record/presentation/pose_painter.dart';
import 'package:flutter_autoreps/core/network/api_client.dart';
import 'package:flutter_autoreps/core/config/api_config.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});
  static const routeName = '/camera';

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  String? _error;
  bool _initializing = true;

  // Squat detection
  final SquatDetectorService _squatDetector = SquatDetectorService();
  bool _isProcessing = false;
  bool _isDetectionActive = false;
  int? _countdown;

  // Workout tracking
  DateTime? _workoutStartTime;
  int _totalReps = 0;
  int _invalidReps = 0;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _initSquatDetector();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _error = 'No camera found on this device.';
          _initializing = false;
        });
        return;
      }

      // Load camera position preference from settings
      final prefs = await SharedPreferences.getInstance();
      final cameraPositionPref = prefs.getString('camera_position') ?? 'Front';
      final preferredDirection = cameraPositionPref == 'Front'
          ? CameraLensDirection.front
          : CameraLensDirection.back;

      // Select camera based on user preference
      final CameraDescription camera = cameras.firstWhere(
        (c) => c.lensDirection == preferredDirection,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );
      await controller.initialize();

      if (!mounted) return;

      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize camera: $e';
        _initializing = false;
      });
    }
  }

  Future<void> _initSquatDetector() async {
    try {
      await _squatDetector.initialize();
      // Setup callback for invalid reps
      _squatDetector.onInvalidRep = () {
        setState(() {
          _invalidReps++;
        });
      };
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load ML model: $e')));
      }
    }
  }

  void _startDetection() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (!_squatDetector.isInitialized) return;

    _startCountdown();
  }

  Future<void> _startCountdown() async {
    // Load countdown duration from settings
    final prefs = await SharedPreferences.getInstance();
    final countdownDuration = prefs.getDouble('countdown_duration') ?? 3.0;
    final countdownStart = countdownDuration.toInt();

    // Start countdown from saved duration
    for (int i = countdownStart; i > 0; i--) {
      setState(() {
        _countdown = i;
      });
      await Future.delayed(const Duration(seconds: 1));
    }

    // Clear countdown and start detection
    setState(() {
      _countdown = null;
      _isDetectionActive = true;
      _workoutStartTime = DateTime.now();
      _totalReps = 0;
      _invalidReps = 0;
    });

    _controller!.startImageStream((CameraImage image) {
      _processImage(image);
    });
  }

  void _stopDetection() {
    if (_controller != null && _controller!.value.isStreamingImages) {
      _controller!.stopImageStream();
    }
    setState(() {
      _isDetectionActive = false;
      _totalReps = _squatDetector.repCount;
    });

    // Show summary dialog
    if (_workoutStartTime != null) {
      _showWorkoutSummary();
    }
  }

  Future<void> _processImage(CameraImage image) async {
    if (_isProcessing || !_isDetectionActive) return;
    _isProcessing = true;

    try {
      final inputImage = _convertToInputImage(image);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      await _squatDetector.detectSquat(inputImage);

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // Silently handle errors in production
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _convertToInputImage(CameraImage image) {
    if (_controller == null) return null;

    final camera = _controller!.description;
    InputImageRotation? rotation;

    if (camera.lensDirection == CameraLensDirection.front) {
      rotation = InputImageRotation.rotation270deg;
    } else {
      rotation = InputImageRotation.rotation90deg;
    }

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _squatDetector.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Record',
      showBottomNav: false,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Squat Counter',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Expanded(child: Center(child: _buildBody(context))),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_initializing) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text('Initializing camera...'),
        ],
      );
    }

    if (_error != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _initCamera, child: const Text('Retry')),
        ],
      );
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: const [Text('Camera unavailable')],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate proper camera preview dimensions
        final controller = _controller!;
        final size = controller.value.previewSize!;

        // Camera aspect ratio (width / height)
        var cameraAspect = size.aspectRatio;

        // Screen aspect ratio
        final screenAspect = constraints.maxWidth / constraints.maxHeight;

        double scale;
        if (cameraAspect < screenAspect) {
          // Camera is taller than screen
          scale = constraints.maxWidth / size.height;
        } else {
          // Camera is wider than screen
          scale = constraints.maxHeight / size.width;
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            // Camera preview with proper scaling
            Center(
              child: Transform.scale(
                scale: scale,
                child: AspectRatio(
                  aspectRatio: 1 / cameraAspect,
                  child: CameraPreview(controller),
                ),
              ),
            ),

            // Pose overlay (skeleton visualization)
            if (_isDetectionActive && _squatDetector.lastPose != null)
              Center(
                child: Transform.scale(
                  scale: scale,
                  child: AspectRatio(
                    aspectRatio: 1 / cameraAspect,
                    child: CustomPaint(
                      painter: PosePainter(
                        pose: _squatDetector.lastPose,
                        // ML Kit returns rotated coordinates, so swap width/height
                        imageSize: Size(size.height, size.width),
                      ),
                    ),
                  ),
                ),
              ),

            // Countdown overlay
            if (_countdown != null)
              Center(
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.blue.shade400, Colors.blue.shade700],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.5),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$_countdown',
                      style: const TextStyle(
                        fontSize: 100,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(blurRadius: 10, color: Colors.black45),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Model output display
            if (_isDetectionActive && _countdown == null)
              Positioned(
                top: 20,
                left: 20,
                right: 20,
                child: Column(
                  children: [
                    // Rep counter - large and centered
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.blue.shade600, Colors.blue.shade800],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.fitness_center,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'REPS',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white70,
                                  letterSpacing: 2,
                                ),
                              ),
                              Text(
                                '${_squatDetector.repCount}',
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Bottom status bar
            if (_isDetectionActive && _countdown == null)
              Positioned(
                bottom: 120,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // State and body visibility row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // State indicator
                          Expanded(
                            child: _buildStatusCard(
                              label: 'STATE',
                              value: _squatDetector.currentState == 'down'
                                  ? 'DOWN'
                                  : _squatDetector.currentState == 'up'
                                  ? 'UP'
                                  : 'READY',
                              color: _squatDetector.currentState == 'down'
                                  ? Colors.green
                                  : _squatDetector.currentState == 'up'
                                  ? Colors.orange
                                  : Colors.grey,
                              icon: _squatDetector.currentState == 'down'
                                  ? Icons.arrow_downward
                                  : _squatDetector.currentState == 'up'
                                  ? Icons.arrow_upward
                                  : Icons.pause,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Lower body visibility
                          Expanded(
                            child: _buildStatusCard(
                              label: 'VISIBILITY',
                              value: _squatDetector.isLowerBodyVisible
                                  ? 'GOOD'
                                  : 'ADJUST',
                              color: _squatDetector.isLowerBodyVisible
                                  ? Colors.green
                                  : Colors.red,
                              icon: _squatDetector.isLowerBodyVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Form status
                          Expanded(
                            child: _buildStatusCard(
                              label: 'FORM',
                              value: _squatDetector.isFormCorrect
                                  ? 'CORRECT'
                                  : 'ADJUST',
                              color: _squatDetector.isFormCorrect
                                  ? Colors.green
                                  : Colors.orange,
                              icon: _squatDetector.isFormCorrect
                                  ? Icons.check_circle
                                  : Icons.warning,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            // Control buttons at the bottom
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Reset button
                  if (_isDetectionActive)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: FloatingActionButton(
                        heroTag: 'reset',
                        backgroundColor: Colors.orange,
                        onPressed: () {
                          setState(() {
                            _squatDetector.resetCounter();
                          });
                        },
                        child: const Icon(Icons.refresh),
                      ),
                    ),
                  // Start/Stop button
                  FloatingActionButton.extended(
                    heroTag: 'toggle',
                    backgroundColor: _isDetectionActive || _countdown != null
                        ? Colors.red
                        : Colors.green,
                    onPressed: (_countdown != null)
                        ? null
                        : () {
                            if (_isDetectionActive) {
                              _stopDetection();
                            } else {
                              _startDetection();
                            }
                          },
                    icon: Icon(
                      _isDetectionActive ? Icons.stop : Icons.play_arrow,
                    ),
                    label: Text(
                      _countdown != null
                          ? 'STARTING...'
                          : (_isDetectionActive ? 'STOP' : 'START'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusCard({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showWorkoutSummary() {
    final durationSec = _workoutStartTime != null
        ? DateTime.now().difference(_workoutStartTime!).inSeconds
        : 0;
    final validReps = _totalReps - _invalidReps;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          'Workout Summary',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSummaryRow('Total Reps', _totalReps.toString(), Colors.blue),
            const SizedBox(height: 12),
            _buildSummaryRow('Valid Reps', validReps.toString(), Colors.green),
            const SizedBox(height: 12),
            _buildSummaryRow(
              'Invalid Reps',
              _invalidReps.toString(),
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              'Duration',
              '${(durationSec / 60).floor()}m ${durationSec % 60}s',
              Colors.purple,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Delete - just reset and close
              setState(() {
                _workoutStartTime = null;
                _totalReps = 0;
                _invalidReps = 0;
              });
              Navigator.of(context).pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () async {
              // Save to API
              await _saveWorkoutData(
                _totalReps,
                validReps,
                _invalidReps,
                durationSec,
              );
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveWorkoutData(
    int reps,
    int validReps,
    int invalidReps,
    int durationSec,
  ) async {
    try {
      final apiClient = ApiClient();
      final response = await apiClient.post(
        ApiConfig.workout,
        body: {
          'reps': reps,
          'validReps': validReps,
          'invalidReps': invalidReps,
          'durationSec': durationSec,
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Workout saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to save workout');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving workout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
