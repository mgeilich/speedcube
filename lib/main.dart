import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'widgets/learn_options_sheet.dart';
import 'widgets/premium_upsell_sheet.dart';
import 'utils/logging_config.dart';
import 'models/cube_state.dart';
import 'widgets/layer_by_layer_guide_sheet.dart';
import 'widgets/home_header.dart';
import 'widgets/cube_interactive_view.dart';
import 'widgets/solve_controls.dart';
import 'widgets/introduction_sheet.dart';
import 'widgets/settings_sheet.dart';

import 'widgets/ar_scan_screen.dart';
import 'utils/premium_manager.dart';
import 'controllers/home_controller.dart';
import 'dart:async';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initLogging();
  await PremiumManager().initPrefs();
  runApp(const SpeedCubeApp());
  PremiumManager().initIAP(); // Asynchronous, non-blocking
}

class SpeedCubeApp extends StatelessWidget {
  const SpeedCubeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "SpeedCube AR",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'sans-serif', // Use system fonts to avoid Roboto download
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const SpeedCubeHome(),
    );
  }
}

class SpeedCubeHome extends StatefulWidget {
  const SpeedCubeHome({super.key});

  @override
  State<SpeedCubeHome> createState() => _SpeedCubeHomeState();
}

class _SpeedCubeHomeState extends State<SpeedCubeHome>
    with TickerProviderStateMixin {
  late HomeController _homeController;

  @override
  void initState() {
    super.initState();
    _homeController = HomeController(vsync: this);
    _homeController.addListener(_onControllerUpdate);
    _homeController.onDemoFinished = _onDemoFinished;
    _homeController.onReviewPromptRequested = _showReviewPrompt;
  }

  void _onDemoFinished(int? stepIndex, String? demoType) {
    if (stepIndex != null) {
      _showLayerByLayerGuide(initialStepIndex: stepIndex);
    }
  }

  void _onControllerUpdate() {
    setState(() {});
  }

  @override
  void dispose() {
    _homeController.removeListener(_onControllerUpdate);
    _homeController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    _homeController.rotationY =
        _homeController.rotationY; // Just to trigger update if needed
    _lastRotationPosition = details.localPosition;
  }

  Offset? _lastRotationPosition;

  void _onPanUpdate(DragUpdateDetails details) {
    if (_lastRotationPosition != null) {
      final delta = details.localPosition - _lastRotationPosition!;
      _homeController.rotationY += delta.dx * 0.01;
      _homeController.rotationX += delta.dy * 0.01;
      _lastRotationPosition = details.localPosition;
    }
  }

  void _onPanEnd(DragEndDetails details) {
    _lastRotationPosition = null;
  }

  Future<void> _startScan() async {
    if (kIsWeb) {
      _showWebDemoPopup();
      return;
    }

    if (!PremiumManager().canAccessFeature('ar_scan')) {
      _showPremiumUpsell();
      return;
    }

    final scannedState = await Navigator.of(context).push<CubeState>(
      MaterialPageRoute(builder: (context) => const ARScanScreen()),
    );

    if (scannedState != null) {
      _homeController.updateCubeState(scannedState);
    }
  }

  void _showWebDemoPopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text(
          "Web Version",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "The web version is for demonstration purposes only. Premium features in the mobile app include the ability to scan and solve your own cube and a step-by-step solution analysis tool.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Got it",
                style: TextStyle(color: Color(0xFF6366F1))),
          ),
        ],
      ),
    );
  }

  void _showPremiumUpsell() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PremiumUpsellSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Column(
          children: [
            HomeHeader(
              onScanPressed: _startScan,
              onLearnPressed: () => _showLearnMenu(),
              onSettingsPressed: _showSettings,
            ),
            CubeInteractiveView(
              cubeState: _homeController.cubeState,
              rotationX: _homeController.rotationX,
              rotationY: _homeController.rotationY,
              animatingMove: _homeController.animationController.isAnimating
                  ? _homeController.animationController.currentMove
                  : null,
              animationProgress: _homeController.animationController.isAnimating
                  ? _homeController.animationController.progress
                  : 0,
              stickerLabels: _homeController.stickerLabels,
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              showingSolution: _homeController.showingSolution,
              onExit: _homeController.isDemo
                  ? _homeController.cancelDemo
                  : _homeController.resetToSaved,
            ),
            SolveControls(
              showingSolution: _homeController.showingSolution,
              showExplanations: _homeController.showExplanations,
              moveIndex: _homeController.moveIndex,
              solutionStartIndex: _homeController.solutionStartIndex,
              moveHistory: _homeController.moveHistory,
              analysisController: _homeController.analysisController,
              isScrambling: _homeController.isScrambling,
              isSolving: _homeController.isSolving,
              isAnimating: _homeController.animationController.isAnimating,
              cubeState: _homeController.cubeState,
              scrambleLength: _homeController.scrambleLength,
              onScrambleLengthChanged: (val) =>
                  _homeController.scrambleLength = val,
              onScramble: _homeController.scramble,
              onSolve: _homeController.solve,
              onSeek: _homeController.handleAnalysisSeek,
              onSeekStart: _homeController.handleAnalysisSeekStart,
              onShowWebDemo: _showWebDemoPopup,
              isDemo: _homeController.isDemo,
              onCancelDemo: _homeController.cancelDemo,
              onReset: _homeController.resetToSaved,
              canReset: _homeController.canReset,
              isScanned: _homeController.isScanned,
            ),
          ],
        ),
      ),
    );
  }

  void _showIntroduction() {
    _homeController.showingSolution = false;
    _homeController.path = null;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const IntroductionSheet(),
    ).then((_) {
      // Logic for when intro is closed
    });
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SettingsSheet(),
    );
  }

  void _showLearnMenu({int initialStepIndex = -1}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LearnOptionsSheet(
        onSelectIntroduction: () {
          _showIntroduction();
        },
        onSelectLayerByLayerMethod: () {
          _showLayerByLayerGuide(initialStepIndex: initialStepIndex);
        },
      ),
    );
  }

  void _showLayerByLayerGuide({int initialStepIndex = -1}) {
    _homeController.showingSolution = false;
    _homeController.path = null;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LayerByLayerGuideSheet(
        initialExpandedStepIndex: initialStepIndex,
        onDemoRequested: (stepIndex, initialState,
            {moves,
            initialRotationX,
            targetRotationX,
            initialRotationY,
            targetRotationY,
            demoType,
            stickerLabels,
            targetPieces}) {
          _homeController.handleDemoRequested(
            stepIndex,
            initialState,
            moves: moves,
            initialRotationX: initialRotationX,
            targetRotationX: targetRotationX,
            initialRotationY: initialRotationY,
            targetRotationY: targetRotationY,
            demoType: 'beginner',
            stickerLabels: stickerLabels,
            targetPieces: targetPieces,
          );
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showReviewPrompt() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars, color: Color(0xFFFACC15), size: 48),
            const SizedBox(height: 16),
            const Text(
              "Enjoying SpeedCube?",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Your feedback helps us make the app even better for everyone!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Maybe Later",
                        style: TextStyle(color: Colors.white54)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // In a real app, use launchUrl or in_app_review here
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF818CF8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Rate Now",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
