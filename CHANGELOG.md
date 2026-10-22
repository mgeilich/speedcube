# Changelog

All notable changes to the SpeedCube AR project will be documented in this file.

## [2026.10.0] - 2026-10-22

### Added
- **iPhone Duo Split Screens**: When unfolded (and on iPad or landscape iPhone), the home screen shows the scramble and the solver side by side, and tutorials open beside the Algorithm Library, including from the library button and the beginner guides.
- **Method Comparison**: "Compare all methods" solves the current scramble with every method and shows move counts, stage breakdowns and solve times side by side; tapping a method plays that exact solution.

### Fixed
- **Roux Solver**: Checks now use fixed reference colours instead of M-slice centres, and CMLL/LSE handle U-layer alignment and edge orientation correctly. 100/100 test scrambles solve (previously about 3 in 4), averaging under 5 seconds instead of 34.
- **Heise Solver**: Fixed move translation for rotated orientations and replaced the 2x2x2 block search with an exact distance table. 100/100 test scrambles solve, averaging about 1 second.
- **Cover Screen Layout**: The header no longer overflows on the Duo's narrow outer display, and all screens stay clear of its side status strip.
- **Stage Colours**: Yellow Cross and Edge Orientation now use their intended colours; Kociemba's two phases are distinguishable.

### Changed
- Built with Flutter 3.47.7 for Xcode 27 and the iOS 27 SDK.

## [2026.9.1] - 2026-09-03

### Fixed
- **In-App Purchase Persistence**: Fixed an issue where the Pro unlock status was reset upon app relaunch, ensuring purchased or restored Pro features persist across sessions without manual re-restoration.

## [2026.5.3] - 2026-05-19

### Added
- **Finger Trick Interactive Library**: Implemented a comprehensive finger trick guide with instructional sequences and single-step demo navigation for algorithms.
- **Finger Trick Video Integration**: Added hardware-compatible, slow-motion video demonstrations of finger tricks into the learning modules.
- **Visual Overlays**: Developed a visual 3D arrow and "ghost hand" overlay system that projects precise finger placement logic over the interactive cube model.
- **Handedness Support**: Added dynamic mirroring logic (Righty/Lefty) for finger trick instructions and visual overlays to improve accessibility.

## [2026.5.2] - 2026-05-12

### Fixed
- **F2L Algorithm Library Audit**: Performed a comprehensive audit and correction of all 16 F2L cases. Standardized naming, improved descriptions with explicit slot information, and verified all algorithm and setup sequences for 100% simulation accuracy.
- **OLL/PLL Stability**: Fixed several incorrect algorithms and setup sequences in the OLL and PLL libraries to ensure reliable solves and accurate pedagogical demonstrations.
- **Standardized Notation**: Unified the internal representation of cube moves to prevent visual artifacts during "Left" face algorithmic sequences.

## [2026.5.1] - 2026-05-07

### Added
- **Heise Method Support**: Integrated a full solver and interactive guide for the Heise Method, including block-building and commutator finish logic.
- **Solver Statistics Refactor**: Moved per-stage move statistics to a dedicated popup sheet to maximize vertical space for move explanations.
- **Enhanced UI Controls**: Added a prominent "STATS" button with haptic feedback and improved the prominence of active solve stages.
- **Move Rationale Improvements**: Expanded the depth of move-by-move explanations for all methods.

### Fixed
- Optimized vertical layout in the solver UI to prevent overlapping text on smaller devices.
- Corrected minor visual inconsistencies in the CFOP XCross tutorial.

## [2026.4.0] - 2026-04-23

### Added
- **Finalized Petrus Method Support**: Completed the Petrus method solver and interactive guide with 100% solve reliability and detailed block-building stage illustrations (2x2x2, 2x2x3, F2L, EO, LL).
- **Winter Variation (WV) Algorithm Library**: Introduced a new advanced algorithm category to the library, featuring 27 WV cases to optimize Last Layer solves (Premium feature).
- **Enhanced ZZ Method Tutorial**: Simplified the EOLine stage and clarified edge orientation rules for a better beginner learning experience.
- **Roux Method Improvements**: Refined M-slice logic and block-building demonstrations for improved visual clarity during solves.

### Fixed
- **Premium Upsell Corrections**: Updated the premium features list to correctly reflect that the Layer-by-Layer (LBL) method is part of the free app.
- **Solver Reliability**: Resolved various edge-case failures in the Petrus and ZZ solvers through architectural improvements and increased search budgets.
- **UI Polish**: Fixed several camera transition and sticker highlighting issues in the interactive guides.

## [2026.3.0] - 2026-04-20

### Added
- **Roux Method Support**: Introduced a full solver and interactive tutorial for the Roux method, featuring efficient block-building and M-slice logic.
- **ZZ Method Support**: Added a memory-efficient ZZ solver and specialized tutorial focusing on EOLine and color neutrality.
- **Enhanced Solver Architecture**: Implemented a parent-pointer based BFS for all solvers, significantly reducing memory usage and allowing for larger search budgets without crashes.
- **Tutorial UX Polish**: Optimized camera transitions and reorientation moves for Roux and ZZ guides to improve visual clarity.

### Fixed
- Resolved a performance regression in the BFS search that could lead to Out-Of-Memory errors on complex scrambles.
- Corrected various small UI inconsistencies in the tutorial move-sequencing demos.

## [2026.2.0] - 2026-04-07

### Added
- **CFOP Advanced White Cross**: Replaced the beginner "Daisy Method" with an optimized BFS-based direct cross solver.
- **Improved LBL Tutorial Step 4**: Refactored the "Yellow Cross" stage to start with a deterministic "dot" state and include correct reorientation moves for an improved learning experience.
- **Consistent Tutorial Orientation**: Standardized the Step 6 (Permutation) tutorial to use the correct Yellow-on-Top orientation across all demos and illustrations.

### Fixed
- Resolved an issue in the LBL tutorial where Stage 4 (Yellow Cross) would incorrectly start with a completed cross in some cases.
- Fixed orientation inconsistencies in the Step 6 permutation demos.

## [2026.1.1] - 2026-04-06

### Initial Release Improvements
- Stabilization of the Rubik's LBL solver for 100% success rate on random scrambles.
- Integration of pattern-aware beginner method for the last layer.
