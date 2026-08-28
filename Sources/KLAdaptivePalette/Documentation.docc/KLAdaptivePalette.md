# ``KLAdaptivePalette``

Analyze the colors that are actually visible after an image's crop is applied.

## From image geometry to a usable palette

Start with ``KLPaletteRequest``. It carries the source image, visible geometry,
content mode, and host identity used for caching. Pass it to
``KLPaletteAnalyzer/analyze(_:)``. The analyzer plans a bounded raster with
``KLPaletteRasterPlan`` before reading pixels, which keeps cost predictable and
prevents an original camera image from becoming the analysis surface.

The returned ``KLAdaptivePalette`` contains the sampled edge color, ranked
``KLPaletteCandidate`` values, confidence, an accent, and foreground choices
for measured surfaces. It is a palette result, not a ready-made view. The host
decides where to apply each color and when to invalidate or reuse the analysis.
Changing crop geometry or content mode must produce a new request.

Use ``KLImageContentMode`` to describe the same crop mode used by the host
view. Use ``KLContrastPolicy`` for a foreground on a specific surface.
``KLPerceptualColor/interpolate(from:to:amount:)`` is for transitions between
palette values, while ``KLPerceptualColor/normalizedControlSurface(_:)``
stabilizes a sampled color before placing text or icons over it. The analyzer
does not load images, run OCR, or decide layout.

## Overview

Create a ``KLPaletteRequest`` from a `CGImage` and the host view's geometry, then pass it to ``KLPaletteAnalyzer/analyze(_:)``. The analyzer uses the limits in ``KLPaletteAnalysisConfiguration`` to create a bounded raster before scanning pixels and retains recent results in a bounded in-memory cache. It preserves the source aspect ratio unless an extreme ratio cannot fit the pixel cap with both dimensions present. The result keeps the edge color, ranked image candidates, a confidence value, a toned accent, and foregrounds selected from each surface's measured luminance. Use ``KLPerceptualColor`` for OKLCH transitions between palette colors.

## Topics

### Analysis

- ``KLPaletteAnalyzer``
- ``KLPaletteAnalysisConfiguration``
- ``KLPaletteRasterPlan``
- ``KLPaletteRequest``
- ``KLImageContentMode``

### Palette models

- ``KLAdaptivePalette``
- ``KLPaletteCandidate``
- ``KLColor``
- ``KLContrastPolicy``
- ``KLPerceptualColor``

Use ``KLPerceptualColor/interpolate(from:to:amount:)`` for perceptual
transitions and ``KLPerceptualColor/normalizedControlSurface(_:)`` to stabilize
a sampled color before placing controls over it.
