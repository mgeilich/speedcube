# Changelog

All notable changes to the SpeedCube AR project will be documented in this file.

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
