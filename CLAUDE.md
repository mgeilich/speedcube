# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

SpeedCube AR (`speedcube_ar`): a **Flutter** app (not native Swift) for scanning a 3x3 cube with the camera, solving it with a choice of human methods, and teaching those methods with an animated 3D cube. Shipped on iOS; android/macos/web/linux/windows folders are Flutter scaffolding.

## Commands

```bash
flutter pub get
flutter analyze                         # lints: package:flutter_lints/flutter.yaml
flutter test                            # all *_test.dart under test/
flutter test test/kociemba_test.dart    # one file
flutter test test/cube_state_test.dart --plain-name "some test name"
flutter run -d <device-id>
flutter build ipa                       # release build for App Store
```

- Only `test/*_test.dart` files are picked up by `flutter test`. Other files in `test/` (`verify_*.dart`, `dump_*.dart`, `repro_*.dart`, `audit_prun.dart`, …) are diagnostic scripts with a `main()`, run individually with `flutter test <file>` or `dart run <file>`.
- The many root-level `test_*.dart`, `debug_*.dart`, `discover_*.dart` files, plus `scratch/` and `tmp/`, are throwaway debugging scripts that import via relative `lib/...` paths (`dart run test_petrus.dart`). They are not part of the app or the test suite; their `*.txt` outputs are logs.
- Several solver tests are stress tests (e.g. 100 random scrambles) and are slow.

## Versioning / release

- Version lives in `pubspec.yaml` as `year.release.patch+build` (e.g. `2026.9.2+8`); the build number after `+` becomes `CFBundleVersion` and must increase with every upload.
- Add an entry to `CHANGELOG.md` for each release; `whats_new_release_notes.md` holds App Store "What's New" copy.
- App icons are generated from `assets/icon/icon.png` via `flutter_launcher_icons` (`dart run flutter_launcher_icons`).
- iOS minimum deployment target is 15.0 (set in both `ios/Podfile` and the Xcode project).
- `docs/` (index.html, support.html) is the public marketing/support site, not developer docs.

## Architecture

**Cube model** (`lib/models/`)
- `CubeState` is a sticker model: six `List<CubeColor>` faces (`u,d,f,b,r,l`), 9 stickers each, immutable-style (`applyMoves` returns a new state). Standard orientation is white Up, green Front.
- `CubeMove` is a face + turns (1, -1, 2) + `isWide`, covering face turns, slices and whole-cube rotations (x/y/z). `CubeMove.optimize` cancels redundant moves.
- `alg_library.dart` (OLL/PLL/F2L/WV algorithms with setup sequences), `trigger_library.dart`, `finger_trick.dart` are static teaching data. Algorithms and their setups are expected to round-trip exactly in simulation — `f2l_algo_test.dart` and related tests check this.

**Solvers** (`lib/solver/`) — one per `SolveMethod` (`kociemba, lbl, cfop, roux, zz, petrus, heise`).
- `services/solver_service.dart` is the single entry point: `SolverService.solve(state:, method:)` awaits `KociembaTables.init()`, dispatches to the method's solver, and flattens each solver's list of stage steps (`stageName`, `description`, `algorithmName`, `moves`) into per-move parallel lists in `SolveResult`. The UI uses those per-move labels to show stage/explanation during playback.
- Method solvers are staged and reuse each other: `LblSolver` defines `LblStep`/`Perspective` (which face colors map to U/F so a stage can be solved in a re-oriented frame); `CfopSolver` and others build on LBL helpers; `piece_path_solver.dart` does small searches for placing individual pieces; Kociemba-style coordinates/search are used by several methods for sub-stages (e.g. EO, block building).
- Heavy stages run off the UI thread with `compute(...)`, so isolate entry points must be static/top-level and take a plain input object (see `_SolverInput`).
- `KociembaTables` decodes the binary asset `assets/kociemba_tables.bin` (declared in `pubspec.yaml`) in an isolate at startup. `kociemba_tables_generator.dart` computes the tables in Dart; note `test/generate_static_data.dart` writes a `.dart` file (`lib/solver/kociemba_tables_data.dart`), not the `.bin` the app loads — check the format in `KociembaTables._decodeTables` before regenerating.
- `solver.dart`'s `ReverseSolver` just inverts recorded scramble moves (used for demo/scramble resets).

**App / UI**
- `main.dart` → `SpeedCubeHome`, which owns a `HomeController` (`ChangeNotifier`, `controllers/home_controller.dart`) holding cube state, scramble, current solution and playback position. `AnalysisController` drives the solve-analysis timeline.
- `widgets/cube_renderer.dart` + `animation/cube_animation_controller.dart` render and animate the 3D cube; `cube_interactive_view.dart` handles touch; `solve_controls.dart` / `tape_deck_controls.dart` are playback controls.
- Each method has a guide screen (`*_guide_screen.dart`, `layer_by_layer_guide_sheet.dart`) that drives the same cube view with scripted examples.
- `widgets/ar_scan_screen.dart` scans faces with the `camera` plugin, sampling sticker colors from the image stream (`utils/color_mapper.dart`). There is no ARKit; scanning needs a real device camera.
- `utils/premium_manager.dart` is a singleton `ChangeNotifier` wrapping `in_app_purchase` (product id `SpeedCube_AR_Pro_Unlock`); the unlock is cached in `shared_preferences` (`premium_unlocked`) and loaded at startup via `initPrefs()` so Pro status survives relaunch. Premium-only content is gated through `premium_upsell_sheet.dart`.
- `utils/logging_config.dart` configures `package:logging`; prefer it over `print` in `lib/`.
