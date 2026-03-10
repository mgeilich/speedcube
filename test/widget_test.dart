// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedcube_ar/main.dart';

void main() {
  testWidgets('SpeedCube app smoke test', (WidgetTester tester) async {
    // Set a consistent surface size to avoid overflows in tests
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;

    // Build the app and trigger a frame.
    await tester.pumpWidget(const SpeedCubeApp());

    // Allow background initialization (KociembaSolver.init) to complete
    await tester.pumpAndSettle();

    // Verify the title is displayed
    expect(find.text("SpeedCube AR"), findsOneWidget);

    // Verify control buttons are present
    expect(find.text('Scramble'), findsOneWidget);
    expect(find.byTooltip('Scan Cube'), findsOneWidget);
    expect(find.byTooltip('Learn Mode'), findsOneWidget);

    // Reset surface size after test
    addTearDown(() => tester.view.resetPhysicalSize());
  });
}
