import CoreGraphics
import Foundation

/// A bounded raster plan used by palette analysis.
public struct KLPaletteRasterPlan: Equatable, Sendable {
    /// The source image width in pixels.
    public let sourceWidth: Int
    /// The source image height in pixels.
    public let sourceHeight: Int
    /// The analysis raster width in pixels.
    public let rasterWidth: Int
    /// The analysis raster height in pixels.
    public let rasterHeight: Int

    /// The source image pixel count.
    public var sourcePixelCount: Int {
        sourceWidth * sourceHeight
    }

    /// The bounded analysis pixel count.
    public var rasterPixelCount: Int {
        rasterWidth * rasterHeight
    }

    /// The number of bytes in the RGBA analysis buffer.
    public var rasterByteCount: Int {
        rasterPixelCount * Self.rgbaComponentCount
    }

    private static let rgbaComponentCount = 4

    init(
        sourceWidth: Int,
        sourceHeight: Int,
        rasterWidth: Int,
        rasterHeight: Int
    ) {
        self.sourceWidth = sourceWidth
        self.sourceHeight = sourceHeight
        self.rasterWidth = rasterWidth
        self.rasterHeight = rasterHeight
    }

    func rasterRect(forSourceRect rect: CGRect) -> CGRect {
        let scaleX = Double(rasterWidth) / Double(sourceWidth)
        let scaleY = Double(rasterHeight) / Double(sourceHeight)
        return CGRect(
            x: rect.minX * scaleX,
            y: rect.minY * scaleY,
            width: rect.width * scaleX,
            height: rect.height * scaleY
        )
    }
}

/// Resource limits applied before image pixels are scanned.
public struct KLPaletteAnalysisConfiguration: Equatable, Sendable {
    /// The package default for the longest side of an analysis raster.
    public static let standardMaximumRasterDimension = 512
    /// The package default for total analysis pixels.
    public static let standardMaximumRasterPixelCount = 262_144

    /// The maximum width or height of the analysis raster.
    public let maximumRasterDimension: Int
    /// The maximum total number of pixels in the analysis raster.
    public let maximumRasterPixelCount: Int

    /// The standard bounded-analysis configuration.
    public static let standard = KLPaletteAnalysisConfiguration()

    /// Creates resource limits for palette analysis.
    public init(
        maximumRasterDimension: Int = Self.standardMaximumRasterDimension,
        maximumRasterPixelCount: Int = Self.standardMaximumRasterPixelCount
    ) {
        self.maximumRasterDimension = max(maximumRasterDimension, 1)
        self.maximumRasterPixelCount = max(maximumRasterPixelCount, 1)
    }

    /// Returns the raster size used to analyze an image.
    ///
    /// The source aspect ratio is preserved whenever both resource limits
    /// allow it. For extreme aspect ratios, the pixel cap takes priority over
    /// preserving the ratio because each raster dimension must be at least one.
    public func rasterPlan(for image: CGImage) -> KLPaletteRasterPlan {
        let sourceWidth = max(image.width, 1)
        let sourceHeight = max(image.height, 1)
        let longestSide = max(sourceWidth, sourceHeight)
        let sourcePixelCount = Double(sourceWidth) * Double(sourceHeight)
        let dimensionScale = min(
            Double(maximumRasterDimension) / Double(longestSide),
            1
        )
        let pixelScale = min(
            sqrt(Double(maximumRasterPixelCount) / sourcePixelCount),
            1
        )
        let scale = min(dimensionScale, pixelScale)
        var rasterWidth = max(Int(floor(Double(sourceWidth) * scale)), 1)
        var rasterHeight = max(Int(floor(Double(sourceHeight) * scale)), 1)
        if rasterWidth * rasterHeight > maximumRasterPixelCount {
            if rasterWidth >= rasterHeight {
                rasterWidth = max(maximumRasterPixelCount / rasterHeight, 1)
            } else {
                rasterHeight = max(maximumRasterPixelCount / rasterWidth, 1)
            }
        }
        return KLPaletteRasterPlan(
            sourceWidth: sourceWidth,
            sourceHeight: sourceHeight,
            rasterWidth: rasterWidth,
            rasterHeight: rasterHeight
        )
    }
}
