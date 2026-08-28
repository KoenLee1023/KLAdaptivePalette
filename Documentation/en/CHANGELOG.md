# Changelog

## 0.1.2

- The analyzer's in-memory palette cache now uses a bounded least-recently-used policy.

## 0.1.1

- Restored raster-sample cleanup for textured neutral and chromatic edges while preserving flat artwork colors.
- Bounded analysis raster dimensions and pixel allocation through `KLPaletteAnalysisConfiguration`.
- Added public OKLCH interpolation through `KLPerceptualColor`.

## 0.1.0

- Initial public release with visible-crop palette analysis, deterministic caching, tests, DocC, and demos.
