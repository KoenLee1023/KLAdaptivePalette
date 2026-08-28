# KLAdaptivePalette

> Languages: [English](README.md) · [简体中文](Documentation/zh-Hans/README.md) · [繁體中文](Documentation/zh-Hant/README.md) · [日本語](Documentation/ja/README.md) · [한국어](Documentation/ko/README.md)

`KLAdaptivePalette` analyzes the visible part of an image and returns colors that can be used for a surface, text, tint, or accent. The analyzer works on a bounded raster instead of the original pixel dimensions. This keeps the cost predictable for photos and large media.

The analysis is aware of the host container. A request can describe `.aspectFill` or `.aspectFit` rendering and an anchor point, so the result is based on the pixels the user is likely to see rather than an unrelated corner of the source image.

```swift
let request = KLPaletteRequest(
    image: image,
    cacheID: mediaID,
    containerSize: size,
    contentMode: .aspectFill,
    anchor: CGPoint(x: 0.5, y: 0.5)
)

let palette = KLPaletteAnalyzer().analyze(request)
let background = palette.lightBackground
let foreground = palette.lightForeground
```

## Public API

`KLPaletteAnalyzer` is the entry point. `analyze(_:)` returns `KLAdaptivePalette`, which contains the source color, edge color, weighted candidates, confidence, tint, and light and dark surface pairs. `cacheKey(for:)` creates a stable key for a host cache. The analyzer does not own a disk cache and does not load images for the host.

`KLPaletteRequest` contains the `CGImage`, a host-owned `cacheID`, the displayed container size, `KLImageContentMode`, and the normalized `anchor`. `KLImageContentMode` distinguishes the visible region used by aspect-fit and aspect-fill layouts.

`KLPaletteAnalysisConfiguration` controls `maximumRasterDimension` and `maximumRasterPixelCount`. Use `rasterPlan(for:)` to inspect the resulting bounded size before analysis. `KLContrastPolicy.foreground(for:)` chooses a readable foreground for a background. `KLPerceptualColor.interpolate` and `normalizedControlSurface(_:)` are available when a host needs a perceptual transition.

The returned `KLColor` stores linear red, green, blue, and alpha components and exposes `relativeLuminance`. It is a value type and can be adapted to `SwiftUI.Color` or `UIColor` by the host.

## Installation

```swift
dependencies: [
    .package(
        url: "https://github.com/KoenLee1023/KLAdaptivePalette.git",
        from: "0.1.2"
    )
]
```

Add the `KLAdaptivePalette` product to the target that imports it.

## Boundaries

The package analyzes an already decoded `CGImage`. It does not download media, persist palettes, choose a UI theme, or apply colors to views. Cache lifetime and invalidation remain the responsibility of the application.

See [English documentation](Documentation/en/README.md) or the localized directories for 简体中文, 繁體中文, 日本語, and 한국어.

## Demos

- [Palette inspector](Examples/PaletteInspector)
- [Adaptive surface](Examples/AdaptiveSurface)

## Requirements

- iOS 17 or later
- macOS 14 or later
- Swift 6.0 or later
- MIT License

API Documentation: [DocC](https://labs.wondays.space/documentation/en/kladaptivepalette)
