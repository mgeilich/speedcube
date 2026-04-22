import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'widgets/learn_options_sheet.dart';
import 'widgets/premium_upsell_sheet.dart';
import 'utils/logging_config.dart';
import 'models/cube_state.dart';
import 'models/cube_move.dart';
import 'widgets/layer_by_layer_guide_sheet.dart';
import 'widgets/cfop_guide_screen.dart';
import 'widgets/roux_guide_screen.dart';
import 'widgets/zz_guide_screen.dart';
import 'widgets/petrus_guide_screen.dart';
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
    _homeController.initSettings();
    _homeController.addListener(_onControllerUpdate);
    _homeController.onDemoFinished = _onDemoFinished;
    _homeController.onReviewPromptRequested = _showReviewPrompt;
    _homeController.onPremiumUpsellRequested = _showPremiumUpsell;
  }

  void _onDemoFinished(int? stepIndex, String? demoType) {
    if (stepIndex != null) {
      if (demoType == 'advanced') {
        _showCfopGuide(initialStepIndex: stepIndex);
      } else if (demoType == 'roux') {
        _showRouxGuide(initialStepIndex: stepIndex);
      } else if (demoType == 'zz') {
        _showZzGuide(initialStepIndex: stepIndex);
      } else if (demoType == 'petrus') {
        _showPetrusGuide(initialStepIndex: stepIndex);
      } else {
        _showLayerByLayerGuide(initialStepIndex: stepIndex);
      }
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
              onLearnPressed: _showLearnMenu,
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
              onRandomize: _homeController.randomize,
              onSolve: _homeController.solve,
              onSeek: _homeController.handleAnalysisSeek,
              onSeekStart: _homeController.handleAnalysisSeekStart,
              onShowWebDemo: _showWebDemoPopup,
              isDemo: _homeController.isDemo,
              onCancelDemo: _homeController.cancelDemo,
              onReset: _homeController.resetToSaved,
              canReset: _homeController.canReset,
              isScanned: _homeController.isScanned,
              selectedMethod: _homeController.selectedSolveMethod,
              onMethodChanged: _homeController.setSelectedSolveMethod,
            ),
          ],
        ),
      ),
    );
  }

  void _showIntroduction() {
    _homeController.showingSolution = false;
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
        onSelectIntroduction: _showIntroduction,
        onSelectLayerByLayerMethod: () {
          _showLayerByLayerGuide(initialStepIndex: initialStepIndex);
        },
        onSelectCfopMethod: () {
          _showCfopGuide(initialStepIndex: initialStepIndex);
        },
        onSelectRouxMethod: () {
          _showRouxGuide(initialStepIndex: initialStepIndex);
        },
        onSelectZzMethod: () {
          _showZzGuide(initialStepIndex: initialStepIndex);
        },
        onSelectPetrusMethod: () {
          _showPetrusGuide(initialStepIndex: initialStepIndex);
        },
      ),
    );
  }

  void _showLayerByLayerGuide({int initialStepIndex = -1}) {
    _homeController.showingSolution = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LayerByLayerGuideSheet(
        initialExpandedStepIndex: initialStepIndex != -1
            ? initialStepIndex
            : (_homeController.lastLblStepIndex ?? -1),
        onTabChanged: (index) {
          _homeController.updateLblProgress(index);
        },
        onDemoRequested: (stepIndex, initialState,
            {moves,
            initialRotationX,
            targetRotationX,
            initialRotationY,
            targetRotationY,
            demoType,
            stickerLabels,
            targetPieces}) {
          _onDemoRequested(stepIndex, initialState,
              moves: moves,
              initialRotationX: initialRotationX,
              targetRotationX: targetRotationX,
              initialRotationY: initialRotationY,
              targetRotationY: targetRotationY,
              demoType: 'beginner',
              stickerLabels: stickerLabels,
              targetPieces: targetPieces);
        },
      ),
    );
  }

  void _showCfopGuide({int initialStepIndex = -1}) {
    if (!PremiumManager().canAccessFeature('cfop_tutorial')) {
      _showPremiumUpsell();
      return;
    }

    _homeController.showingSolution = false;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CfopGuideScreen(
          initialExpandedStepIndex: initialStepIndex != -1
              ? initialStepIndex
              : (_homeController.lastCfopStepIndex ?? -1),
          initialScrollOffset: _homeController.lastCfopScrollOffset ?? 0.0,
          initialOllSubIndex: _homeController.lastOllSubTabIndex ?? 0,
          initialPllSubIndex: _homeController.lastPllSubTabIndex ?? 0,
          initialF2lSubIndex: _homeController.lastF2lSubTabIndex ?? 0,
          onTabChanged: (index, {ollSubIndex, pllSubIndex, f2lSubIndex}) {
            _homeController.updateCfopProgress(
              index,
              0.0,
              ollSubIndex: ollSubIndex,
              pllSubIndex: pllSubIndex,
              f2lSubIndex: f2lSubIndex,
            );
          },
          onDemoRequested: (stepIndex, initialState,
              {moves,
              initialRotationX,
              targetRotationX,
              initialRotationY,
              targetRotationY,
              demoType,
              stickerLabels,
              targetPieces,
              scrollOffset,
              ollSubIndex,
              pllSubIndex,
              f2lSubIndex}) {
            if (scrollOffset != null) {
              _homeController.updateCfopProgress(
                stepIndex,
                scrollOffset,
                ollSubIndex: ollSubIndex,
                pllSubIndex: pllSubIndex,
                f2lSubIndex: f2lSubIndex,
              );
            }
            _onDemoRequested(stepIndex, initialState,
                moves: moves,
                initialRotationX: initialRotationX,
                targetRotationX: targetRotationX,
                initialRotationY: initialRotationY,
                targetRotationY: targetRotationY,
                demoType: 'advanced',
                stickerLabels: stickerLabels,
                targetPieces: targetPieces);
          },
        ),
      ),
    );
  }

  void _onDemoRequested(int stepIndex, CubeState initialState,
      {List<CubeMove>? moves,
      double? initialRotationX,
      double? targetRotationX,
      double? initialRotationY,
      double? targetRotationY,
      String? demoType,
      Map<CubeFace, Map<int, String>>? stickerLabels,
      List<int>? targetPieces}) {
    _homeController.handleDemoRequested(
      stepIndex,
      initialState,
      moves: moves,
      initialRotationX: initialRotationX,
      targetRotationX: targetRotationX,
      initialRotationY: initialRotationY,
      targetRotationY: targetRotationY,
      demoType: demoType ?? 'beginner',
      stickerLabels: stickerLabels,
      targetPieces: targetPieces,
    );
    // Dismiss the learn options / guide sheet
    Navigator.pop(context);
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

  void _showRouxGuide({int? initialStepIndex, double? scrollOffset, int? cmllSubIndex, int? lseSubIndex}) {
    if (!PremiumManager().canAccessFeature('roux_tutorial')) {
      _showPremiumUpsell();
      return;
    }

    _homeController.showingSolution = false;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RouxGuideScreen(
          initialExpandedStepIndex: initialStepIndex ?? _homeController.lastRouxStepIndex ?? 0,
          initialScrollOffset: scrollOffset ?? _homeController.lastRouxScrollOffset ?? 0,
          initialCmllSubIndex: cmllSubIndex ?? _homeController.lastCmllSubTabIndex ?? 0,
          initialLseSubIndex: lseSubIndex ?? _homeController.lastLseSubTabIndex ?? 0,
          onTabChanged: (stepIndex, {cmllSubIndex, lseSubIndex}) {
            _homeController.updateRouxProgress(
              stepIndex,
              0,
              cmllSubIndex: cmllSubIndex,
              lseSubIndex: lseSubIndex,
            );
          },
          onDemoRequested: (stepIndex, initialState,
              {moves,
              initialRotationX,
              targetRotationX,
              initialRotationY,
              targetRotationY,
              demoType,
              stickerLabels,
              targetPieces,
              scrollOffset,
              cmllSubIndex,
              lseSubIndex}) {
            if (scrollOffset != null) {
              _homeController.updateRouxProgress(
                stepIndex,
                scrollOffset,
                cmllSubIndex: cmllSubIndex,
                lseSubIndex: lseSubIndex,
              );
            }
            _onDemoRequested(stepIndex, initialState,
                moves: moves,
                initialRotationX: initialRotationX,
                targetRotationX: targetRotationX,
                initialRotationY: initialRotationY,
                targetRotationY: targetRotationY,
                demoType: 'roux',
                stickerLabels: stickerLabels,
                targetPieces: targetPieces);
          },
        ),
      ),
    );
  }

  void _showZzGuide({int? initialStepIndex, double? scrollOffset}) {
    if (!PremiumManager().canAccessFeature('zz_tutorial')) {
      _showPremiumUpsell();
      return;
    }

    _homeController.showingSolution = false;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ZzGuideScreen(
          initialExpandedStepIndex:
              initialStepIndex ?? _homeController.lastZzStepIndex ?? 0,
          initialScrollOffset: scrollOffset ?? _homeController.lastZzScrollOffset ?? 0,
          onTabChanged: (stepIndex) {
            _homeController.updateZzProgress(stepIndex, 0);
          },
          onDemoRequested: (stepIndex, initialState,
              {moves,
              initialRotationX,
              targetRotationX,
              initialRotationY,
              targetRotationY,
              demoType,
              stickerLabels,
              targetPieces,
              scrollOffset}) {
            if (scrollOffset != null) {
              _homeController.updateZzProgress(stepIndex, scrollOffset);
            }
            _onDemoRequested(stepIndex, initialState,
                moves: moves,
                initialRotationX: initialRotationX,
                targetRotationX: targetRotationX,
                initialRotationY: initialRotationY,
                targetRotationY: targetRotationY,
                demoType: 'zz',
                stickerLabels: stickerLabels,
                targetPieces: targetPieces);
          },
        ),
      ),
    );
  }
  void _showPetrusGuide({int? initialStepIndex, double? scrollOffset}) {
    if (!PremiumManager().canAccessFeature('petrus_tutorial')) {
      _showPremiumUpsell();
      return;
    }

    _homeController.showingSolution = false;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PetrusGuideScreen(
          initialExpandedStepIndex: initialStepIndex ?? 0,
          initialScrollOffset: scrollOffset ?? 0,
          onTabChanged: (stepIndex) {
            // Optional: Store progress in HomeController
          },
          onDemoRequested: (stepIndex, initialState,
              {moves,
              initialRotationX,
              targetRotationX,
              initialRotationY,
              targetRotationY,
              demoType,
              stickerLabels,
              targetPieces,
              scrollOffset}) {
            _onDemoRequested(stepIndex, initialState,
                moves: moves,
                initialRotationX: initialRotationX,
                targetRotationX: targetRotationX,
                initialRotationY: initialRotationY,
                targetRotationY: targetRotationY,
                demoType: 'petrus',
                stickerLabels: stickerLabels,
                targetPieces: targetPieces);
          },
        ),
      ),
    );
  }
}
