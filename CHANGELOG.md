# Changelog

All notable changes to the SpeedCube AR project will be documented in this file.

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
