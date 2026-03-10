import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'package:image/image.dart' as img;
import 'dart:math' as math;
import '../models/cube_state.dart';
import '../models/cube_move.dart';
import '../utils/color_mapper.dart';
import 'cube_renderer.dart';

class ARScanScreen extends StatefulWidget {
  const ARScanScreen({super.key});

  @override
  State<ARScanScreen> createState() => _ARScanScreenState();
}

class _ARScanScreenState extends State<ARScanScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isProcessing = false; // Guard against overlapping analysis

  // Scanning state
  int _currentFaceIndex = 0;
  final List<CubeFace> _faceSequence = [
    CubeFace.f, // Front
    CubeFace.r, // Right
    CubeFace.b, // Back
    CubeFace.l, // Left
    CubeFace.u, // Up (Top)
    CubeFace.d, // Down (Bottom)
  ];

  final Map<CubeFace, List<CubeColor>> _scannedFaces = {};
  List<CubeColor> _currentLiveColors = List.filled(9, CubeColor.white);
  bool _hasCapture = false; // Whether we have a snapshot for the current face
  bool _isCenterCorrect =
      false; // Whether the captured center matches expectations
  Timer? _liveAnalysisTimer;
  DateTime? _lastLiveAnalysis;
  bool _isCameraStreaming = false;
  bool _showStartGuide = true; // Show initial instructions

  CubeColor? get _expectedCenterColor {
    if (_currentFaceIndex < 0 || _currentFaceIndex >= _faceSequence.length) {
      return null;
    }
    // Standard orientation: F=Green, R=Red, B=Blue, L=Orange, U=White, D=Yellow
    switch (_faceSequence[_currentFaceIndex]) {
      case CubeFace.f:
        return CubeColor.green;
      case CubeFace.r:
        return CubeColor.red;
      case CubeFace.b:
        return CubeColor.blue;
      case CubeFace.l:
        return CubeColor.orange;
      case CubeFace.u:
        return CubeColor.white;
      case CubeFace.d:
        return CubeColor.yellow;
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      try {
        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          if (!_showStartGuide) {
            _startLiveAnalysis();
          }
        }
      } catch (e) {
        debugPrint('Camera initialization error: $e');
      }
    }
  }

  void _startLiveAnalysis() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (_isCameraStreaming) return;

    _controller!.startImageStream((image) {
      if (_hasCapture || _isProcessing) return;

      final now = DateTime.now();
      if (_lastLiveAnalysis != null &&
          now.difference(_lastLiveAnalysis!).inMilliseconds < 400) {
        return;
      }

      _lastLiveAnalysis = now;
      _processCameraImage(image);
    });
    _isCameraStreaming = true;
  }

  void _processCameraImage(CameraImage image) {
    if (mounted) {
      setState(() {
        _isProcessing = true;
      });
    }

    try {
      final centerX = image.width ~/ 2;
      final centerY = image.height ~/ 2;
      final gridSize = (math.min(image.width, image.height) * 0.6).toInt();
      final boxSize = gridSize ~/ 3;

      final List<CubeColor> detectedColors = [];

      for (int row = 0; row < 3; row++) {
        for (int col = 0; col < 3; col++) {
          // Map UI grid (row, col) to sensor coordinates (x, y)
          // For portrait iOS, the sensor is landscape.
          // 90-degree CW rotation mapping from UI to Sensor:
          final double rowOffset = (row - 1) * boxSize.toDouble();
          final double colOffset = (col - 1) * boxSize.toDouble();

          var x = (centerX + colOffset).toInt();
          var y = (centerY + rowOffset).toInt();

          x = x.clamp(0, image.width - 1);
          y = y.clamp(0, image.height - 1);

          Color rgb;
          if (image.format.group == ImageFormatGroup.yuv420) {
            rgb = _yuvToColor(image, x, y);
          } else if (image.format.group == ImageFormatGroup.bgra8888) {
            rgb = _bgraToColor(image, x, y);
          } else {
            // Fallback for unknown formats
            rgb = Colors.white;
          }

          final int r = (rgb.r * 255).toInt();
          final int g = (rgb.g * 255).toInt();
          final int b = (rgb.b * 255).toInt();

          final mappedColor = ColorMapper.mapRGB(r, g, b);
          detectedColors.add(mappedColor);

          // Verbose logging for all squares to diagnose mapping
          debugPrint(
              '[AR Scan] Live [Row $row, Col $col] (Index ${row * 3 + col}): Sensor($x, $y) -> $mappedColor');
        }
      }

      debugPrint('[AR Scan] Live Grid Order: $detectedColors');

      if (mounted && !_hasCapture) {
        final expected = _expectedCenterColor;
        final actual = detectedColors[4];
        final centerMatch = expected == null || actual == expected;

        setState(() {
          _currentLiveColors = detectedColors;
          _isCenterCorrect = centerMatch;
        });
      }
    } catch (e) {
      debugPrint('[AR Scan] Live analysis error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Color _yuvToColor(CameraImage image, int x, int y) {
    // Y plane is plane 0
    final int yIndex = y * image.planes[0].bytesPerRow + x;
    final int yValue = image.planes[0].bytes[yIndex];

    // UV planes are planes 1 and 2 (usually)
    // For YUV420, UV is half resolution
    final int uvIndex = (y ~/ 2) * image.planes[1].bytesPerRow +
        (x ~/ 2) * (image.planes[1].bytesPerPixel ?? 1);

    final int uValue = image.planes[1].bytes[uvIndex];
    final int vValue = image.planes[2].bytes[uvIndex];

    // Conversion formulas
    int r = (yValue + 1.402 * (vValue - 128)).toInt();
    int g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
        .toInt();
    int b = (yValue + 1.772 * (uValue - 128)).toInt();

    return Color.fromARGB(
      255,
      r.clamp(0, 255),
      g.clamp(0, 255),
      b.clamp(0, 255),
    );
  }

  Color _bgraToColor(CameraImage image, int x, int y) {
    final int bytesPerPixel = image.planes[0].bytesPerPixel ?? 4;
    final int index = y * image.planes[0].bytesPerRow + x * bytesPerPixel;
    final bytes = image.planes[0].bytes;

    // BGRA format
    final int b = bytes[index];
    final int g = bytes[index + 1];
    final int r = bytes[index + 2];

    return Color.fromARGB(255, r, g, b);
  }

  Future<void> _takeSnapshot() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      debugPrint('[AR Scan] Camera not ready');
      return;
    }

    if (_controller!.value.isTakingPicture || _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final imageFile = await _controller!.takePicture();
      final bytes = await imageFile.readAsBytes();
      debugPrint('[AR Scan] Captured ${bytes.length} bytes');

      // Use decodeJpg specifically — takePicture() always produces JPEG on iOS
      final image = img.decodeJpg(bytes);

      if (image == null) {
        debugPrint(
            '[AR Scan] ERROR: decodeJpg returned null for ${bytes.length} bytes');
        if (mounted) {
          setState(() {});
        }
        return;
      }

      debugPrint('[AR Scan] Decoded image: ${image.width}x${image.height}');

      if (mounted) {
        _analyzeImage(image);

        // Sequence-based identification
        final identifiedFace = _faceSequence[_currentFaceIndex];
        final expected = _expectedCenterColor;
        final actual = _currentLiveColors[4];
        final centerMatch = expected == null || actual == expected;

        setState(() {
          _hasCapture = true;
          _isCenterCorrect = centerMatch;
          // Immediate save
          _scannedFaces[identifiedFace] = List.from(_currentLiveColors);
        });

        debugPrint(
            '[AR Scan] Captured Step $_currentFaceIndex -> Mapped to $identifiedFace');
      }
    } catch (e, st) {
      debugPrint('[AR Scan] Analysis error: $e');
      debugPrint('[AR Scan] Stack trace: $st');
      if (mounted) {
        setState(() {});
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _analyzeImage(img.Image image) {
    // The grid is centered in the UI. We need to map UI coordinates to image coordinates.
    // In UI, grid is 280x280 at center.
    // Assuming image aspect ratio matches screen or we use center crop.

    final width = image.width;
    final height = image.height;
    final centerX = width ~/ 2;
    final centerY = height ~/ 2;

    // Size of the grid in image pixels (approximate based on overlay/screenRatio)
    // Take a square relative to the smaller dimension
    final gridSize = (math.min(width, height) * 0.6).toInt();
    final boxSize = gridSize ~/ 3;

    debugPrint('[AR Scan] Grid analysis: gridSize=$gridSize, boxSize=$boxSize');

    final List<CubeColor> detectedColors = [];

    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 3; col++) {
        // Snapshots (decoded img.Image) are already effectively portrait.
        // Direct mapping from UI grid to Image pixels is correct here.
        final double rowOffset = (row - 1) * boxSize.toDouble();
        final double colOffset = (col - 1) * boxSize.toDouble();

        // Row -> Y (Top to Bottom), Col -> X (Left to Right)
        var x = (centerX + colOffset).toInt();
        var y = (centerY + rowOffset).toInt();

        x = x.clamp(0, width - 1);
        y = y.clamp(0, height - 1);

        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        final mappedColor = ColorMapper.mapRGB(r, g, b);
        detectedColors.add(mappedColor);

        debugPrint(
            '[AR Scan] Capture [Row $row, Col $col] (Index ${row * 3 + col}): Portrait Mapping($x, $y) -> $mappedColor');
      }
    }

    debugPrint('[AR Scan] Capture Grid Order: $detectedColors');

    debugPrint('[AR Scan] Final colors: $detectedColors');

    if (mounted) {
      setState(() {
        _currentLiveColors = detectedColors;
      });
      debugPrint(
          '[AR Scan] setState called with ${detectedColors.length} colors');
    }
  }

  @override
  void dispose() {
    _liveAnalysisTimer?.cancel();
    if (_isCameraStreaming) {
      _controller?.stopImageStream();
    }
    _controller?.dispose();
    super.dispose();
  }

  void _loadFace(int index) {
    final face = _faceSequence[index];
    if (_scannedFaces.containsKey(face)) {
      setState(() {
        _currentLiveColors = List.from(_scannedFaces[face]!);
        _hasCapture = true;
        _isCenterCorrect = true; // Previously confirmed faces were correct
      });
    } else {
      setState(() {
        _currentLiveColors = List.filled(9, CubeColor.white);
        _hasCapture = false;
        _isCenterCorrect = false;
      });
    }
  }

  void _onConfirmNextFace() {
    if (!_hasCapture) return;

    setState(() {
      if (_currentFaceIndex < 5) {
        _currentFaceIndex++;
        _loadFace(_currentFaceIndex);
      } else {
        _finishScanning();
      }
    });
  }

  void _onPreviousFace() {
    if (_currentFaceIndex > 0) {
      _currentFaceIndex--;
      _loadFace(_currentFaceIndex);
    }
  }

  bool _isCubeValid() {
    if (_scannedFaces.length < 6) return false;

    final Map<CubeColor, int> counts = {};
    for (final faceColors in _scannedFaces.values) {
      for (final color in faceColors) {
        counts[color] = (counts[color] ?? 0) + 1;
      }
    }

    // A solvable cube must have exactly 9 stickers of each color
    return counts.values.every((count) => count == 9);
  }

  void _finishScanning() {
    if (!_isCubeValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Invalid scan: Exactly 9 of each color required. Please re-scan incorrect faces.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // No extra orientation correction needed.
    // The logical engine matches the 'Row 2 = Front' capture.
    final uFace = _scannedFaces[CubeFace.u]!;
    final dFace = _scannedFaces[CubeFace.d]!;

    final cubeState = CubeState.fromFaces(
      u: uFace,
      d: dFace,
      f: _scannedFaces[CubeFace.f]!,
      b: _scannedFaces[CubeFace.b]!,
      r: _scannedFaces[CubeFace.r]!,
      l: _scannedFaces[CubeFace.l]!,
    );
    Navigator.of(context).pop(cubeState);
  }

  Color _getColorValue(CubeColor color) {
    switch (color) {
      case CubeColor.white:
        return const Color(0xFFF8F9FA);
      case CubeColor.yellow:
        return const Color(0xFFFFD60A);
      case CubeColor.green:
        return const Color(0xFF34C759);
      case CubeColor.blue:
        return const Color(0xFF007AFF);
      case CubeColor.red:
        return const Color(0xFFFF3B30);
      case CubeColor.orange:
        return const Color(0xFFFF9500);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body:
            Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          Transform.scale(
            scale: 1.1, // Slight zoom to fill gaps
            child: Center(
              child: CameraPreview(_controller!),
            ),
          ),

          // Scanning Overlay (3x3 Grid)
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.8), width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Column(
                  children: List.generate(
                      3,
                      (row) => Expanded(
                            child: Row(
                              children: List.generate(
                                  3,
                                  (col) => Expanded(
                                        child: Container(
                                          margin: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.white
                                                    .withValues(alpha: 0.6),
                                                width: 2),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Center(
                                            child: FractionallySizedBox(
                                              widthFactor: 0.75,
                                              heightFactor: 0.75,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: _getColorValue(
                                                          _currentLiveColors[
                                                              row * 3 + col])
                                                      .withValues(alpha: 0.85),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(
                                                              alpha: 0.3),
                                                      blurRadius: 4,
                                                      offset:
                                                          const Offset(0, 2),
                                                    )
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      )),
                            ),
                          )),
                ),
              ),
            ),
          ),

          // Instructions & Progress
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
                // blurStyle: BlurStyle.outer, // This property is not available in BoxDecoration
              ),
              child: Column(
                children: [
                  Text(
                    'STEP ${_currentFaceIndex + 1}: ${_getRotationInstruction(_currentFaceIndex)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_hasCapture)
                    Text(
                      !_isCenterCorrect
                          ? 'Wait! Center must be ${_expectedCenterColor?.name.toUpperCase()}'
                          : (_currentFaceIndex == 5 && _scannedFaces.length == 6
                              ? 'All 6 faces captured! Tap DONE.'
                              : 'Ready? Tap NEXT to confirm'),
                      style: TextStyle(
                        color: _isCenterCorrect
                            ? Colors.white70
                            : const Color(0xFFEF4444),
                        fontSize: 14,
                        fontWeight: _isCenterCorrect
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    )
                  else
                    Text(
                      !_isCenterCorrect
                          ? 'Waiting for ${_expectedCenterColor?.name.toUpperCase()} center face'
                          : 'Aim at the cube face and tap CAPTURE',
                      style: TextStyle(
                        color: _isCenterCorrect
                            ? Colors.white70
                            : (_expectedCenterColor != null
                                ? _getColorValue(_expectedCenterColor!)
                                : const Color(0xFFEF4444)),
                        fontSize: 14,
                        fontWeight: _isCenterCorrect
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 16),
                  // Progress dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                        6,
                        (index) => Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: index <= _currentFaceIndex
                                    ? const Color(0xFF6366F1)
                                    : Colors.white24,
                              ),
                            )),
                  ),
                ],
              ),
            ),
          ),

          // Guide Overlay
          if (_showStartGuide)
            Positioned.fill(
              child: Container(
                color: Colors.black,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Scan the face with the green center in portrait mode with the white center face towards the top. Keep your phone in the same orientation when scanning each face.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    const _CubeGuideGraphic(),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Center the requested face in the scanner and take a picture. Make sure the colors match your cube.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 60),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _showStartGuide = false;
                        });
                        _startLiveAnalysis();
                      },
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              ),
            ),

          // Capture & Next Buttons
          if (!_showStartGuide)
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Left Slot (Previous Button)
                      SizedBox(
                        width: 100,
                        child: _currentFaceIndex > 0
                            ? Center(
                                child: GestureDetector(
                                  onTap: _onPreviousFace,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white10,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white24),
                                    ),
                                    child: const Icon(Icons.arrow_back,
                                        color: Colors.white, size: 28),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),

                      const SizedBox(width: 20),

                      // Center Slot (Capture/Record Button)
                      GestureDetector(
                        onTap: _hasCapture
                            ? () => setState(() => _hasCapture = false)
                            : _takeSnapshot,
                        child: Container(
                          width: 84,
                          height: 84,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: _isProcessing
                                ? const Padding(
                                    padding: EdgeInsets.all(20),
                                    child: CircularProgressIndicator(
                                        color: Colors.black, strokeWidth: 3),
                                  )
                                : Icon(
                                    _hasCapture
                                        ? Icons.fiber_manual_record
                                        : Icons.camera,
                                    color:
                                        _hasCapture ? Colors.red : Colors.black,
                                    size: 40,
                                  ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 20),

                      // Right Slot (Next/Done Button)
                      SizedBox(
                        width: 100,
                        child: _hasCapture
                            ? Center(
                                child: GestureDetector(
                                  onTap: _isCenterCorrect
                                      ? _onConfirmNextFace
                                      : null,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _isCenterCorrect
                                          ? const Color(0xFF6366F1)
                                          : Colors.white10,
                                      shape: BoxShape.circle,
                                      boxShadow: _isCenterCorrect
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFF6366F1)
                                                    .withValues(alpha: 0.4),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              )
                                            ]
                                          : null,
                                    ),
                                    child: Icon(
                                      _currentFaceIndex < 5
                                          ? Icons.arrow_forward
                                          : Icons.check,
                                      color: _isCenterCorrect
                                          ? Colors.white
                                          : Colors.white24,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          // Close Button
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  String _getRotationInstruction(int index) {
    switch (index) {
      case 0:
        return 'Hold Green in front, White on top';
      case 1:
        return 'Rotate cube 90° LEFT';
      case 2:
        return 'Rotate cube 90° LEFT again';
      case 3:
        return 'Rotate cube 90° LEFT again';
      case 4:
        return 'Return to Green, then ROTATE TOWARDS you';
      case 5:
        return 'Return to Green, then ROTATE AWAY from you';
      default:
        return 'Aim at the center sticker';
    }
  }
}

class _CubeGuideGraphic extends StatelessWidget {
  const _CubeGuideGraphic();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: 160,
          height: 160,
          child: CustomPaint(
            painter: CubeRenderer(
              cubeState: CubeState.solved(),
              ghostMode: true,
              rotationX:
                  0.5, // Tilted to show white top (reverted per feedback)
              rotationY: -0.45, // Angled to show green front
            ),
          ),
        ),
      ),
    );
  }
}
