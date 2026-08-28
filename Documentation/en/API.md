# API

`KLAdaptivePalette` turns the visible part of a `CGImage` into a small, stable color model for a host view. It is intended for backgrounds, controls, and readable foregrounds. The package does not load images, retain them, or decide when an application should refresh its UI.

## Analyze a visible image region

Create a `KLPaletteRequest` with the source image, a host-owned `cacheID`, the display `containerSize`, and the same `KLImageContentMode` and `anchor` used by the image view. `aspectFill` analyzes the cropped region that is actually visible. `aspectFit` analyzes the complete image.

`KLPaletteAnalyzer` performs the analysis and returns `KLAdaptivePalette`. The result includes `rawEdgeColor`, the normalized `sourceColor`, ranked `candidates`, a `confidence` value in `0...1`, a `tintColor`, and light and dark background/foreground pairs. `KLContrastPolicy.foreground(for:)` chooses a neutral foreground by comparing contrast against the actual background rather than by assuming a system appearance.

## Bound resource use

`KLPaletteAnalysisConfiguration` limits the raster with `maximumRasterDimension` and `maximumRasterPixelCount`. Its `rasterPlan(for:)` method exposes the exact source size, analysis size, pixel count, and RGBA byte count before scanning. The standard limits are 512 pixels on the longest side and 262,144 pixels in total.

## Tune color normalization

`KLPerceptualColor.interpolate(from:to:amount:)` blends colors in OKLCH space. `KLPerceptualColor.normalizedControlSurface(_:)` preserves useful lightness and hue while suppressing near-gray casts and bounding chroma for controls. Use these functions when the raw image color is too strong for a surface, not as a replacement for the palette analysis.

## Cache safely

The analyzer's cache key is derived from the host `cacheID`, image pixels, display geometry, content mode, and crop anchor. Keep the identifier stable for the same media and change it when the underlying image changes. Equal inputs produce equal keys, so opening a view does not require rescanning unchanged pixels.

## Public types

- `KLColor` is the platform-neutral color value used by the package.
- `KLPaletteCandidate` pairs a representative color with a ranking weight and normalized position.
- `KLImageContentMode` describes the host image layout rule.
- `KLPaletteRequest` is the complete input for one analysis.
- `KLAdaptivePalette` is the analysis result.
- `KLPaletteAnalysisConfiguration` and `KLPaletteRasterPlan` describe bounded work.
- `KLContrastPolicy` selects a readable neutral foreground.
