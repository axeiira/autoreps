// ignore_for_file: use_build_context_synchronously

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_autoreps/widgets/app_scaffold.dart';
import 'package:flutter_autoreps/features/record/data/squat_detector_service.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

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
	bool _isSquatting = false;
	int _repCount = 0;
	bool _isDetectionActive = false;

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

			// Prefer front camera for self-recording
			final CameraDescription camera = cameras.firstWhere(
				(c) => c.lensDirection == CameraLensDirection.front,
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
		} catch (e) {
			if (mounted) {
				ScaffoldMessenger.of(context).showSnackBar(
					SnackBar(content: Text('Failed to load ML model: $e')),
				);
			}
		}
	}

	void _startDetection() {
		if (_controller == null || !_controller!.value.isInitialized) return;
		if (!_squatDetector.isInitialized) return;
		
		setState(() {
			_isDetectionActive = true;
			_repCount = 0;
		});
		_squatDetector.resetReps();

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
		});
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

			final isSquatting = await _squatDetector.detectSquat(inputImage);

			if (mounted) {
				setState(() {
					_isSquatting = isSquatting;
					_repCount = _squatDetector.repCount;
				});
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

		final plane =  image.planes.first;
		
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
							padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
							child: Row(
								children: [
									IconButton(
										icon: const Icon(Icons.arrow_back),
										onPressed: () => Navigator.pop(context),
									),
									const SizedBox(width: 8),
									const Text('Squat Counter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
								],
							),
						),
						Expanded(
							child: Center(
								child: _buildBody(context),
							),
						),
					],
				),
			),
		);
	}

	Widget _buildBody(BuildContext context) {
		if (_initializing) {
			return Column(
				mainAxisSize: MainAxisSize.min,
				children: const [CircularProgressIndicator(), SizedBox(height: 12), Text('Initializing camera...')],
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
						
						// Rep counter at the top
						Positioned(
							top: 20,
							left: 0,
							right: 0,
							child: Center(
								child: Container(
									padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
									decoration: BoxDecoration(
										color: Colors.black.withValues(alpha: 0.7),
										borderRadius: BorderRadius.circular(16),
									),
									child: Column(
										mainAxisSize: MainAxisSize.min,
										children: [
											Text(
												'$_repCount',
												style: const TextStyle(
													fontSize: 64,
													fontWeight: FontWeight.bold,
													color: Colors.white,
												),
											),
											const Text(
												'REPS',
												style: TextStyle(
													fontSize: 16,
													fontWeight: FontWeight.w600,
													color: Colors.white70,
													letterSpacing: 2,
												),
											),
										],
									),
								),
							),
						),
						
						// Status indicator (Squatting/Standing)
						if (_isDetectionActive)
							Positioned(
								top: 160,
								left: 0,
								right: 0,
								child: Center(
									child: Container(
										padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
										decoration: BoxDecoration(
											color: _isSquatting ? Colors.green.withValues(alpha: 0.8) : Colors.orange.withValues(alpha: 0.8),
											borderRadius: BorderRadius.circular(20),
										),
										child: Text(
											_isSquatting ? '🔽 SQUATTING' : '🔼 STANDING',
											style: const TextStyle(
												fontSize: 16,
												fontWeight: FontWeight.bold,
												color: Colors.white,
											),
										),
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
								mainAxisSize: MainAxisSize.min,
								children: [
									if (_isDetectionActive) ...[
										FloatingActionButton(
											heroTag: 'reset',
											backgroundColor: Colors.orange,
											onPressed: () {
												_squatDetector.resetReps();
												setState(() {
													_repCount = 0;
												});
											},
											child: const Icon(Icons.refresh),
										),
										const SizedBox(width: 20),
									],
									FloatingActionButton.extended(
										heroTag: 'toggle',
										backgroundColor: _isDetectionActive ? Colors.red : Colors.green,
										onPressed: () {
											if (_isDetectionActive) {
												_stopDetection();
											} else {
												_startDetection();
											}
										},
										icon: Icon(_isDetectionActive ? Icons.stop : Icons.play_arrow),
										label: Text(_isDetectionActive ? 'STOP' : 'START'),
									),
								],
							),
						),
					],
				);
			},
		);
	}
}
