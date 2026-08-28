import CoreGraphics
import Foundation

/// Extracts deterministic palettes from the image area visible to a host view.
public final class KLPaletteAnalyzer {
    private enum Tuning {
        static let algorithmVersion = "v2"
        static let alphaThreshold: UInt8 = 127
        static let edgeFraction = 0.015
        static let minimumEdgeHeight = 1.0
        static let naturalEdgeTexturePercentile = 0.75
        static let naturalEdgeTextureThreshold = 0.035
        static let neutralEdgeChromaThreshold = 0.045
        static let neutralFamilyMinimumChromaLimit = 0.06
        static let neutralFamilyChromaMargin = 0.035
        static let neutralFamilyChromaPenalty = 0.35
        static let chromaticFamilyHueTolerance = 0.70
        static let chromaticFamilyChromaWeight = 1.8
        static let cleanEdgeSelectionPercentile = 0.78
        static let maximumCandidateCount = 3
        static let confidenceRunnerUpWeight = 0.35
        static let fnvOffsetBasis: UInt64 = 1_469_598_103_934_665_603
        static let fnvPrime: UInt64 = 1_099_511_628_211
        static let seamNeutralChroma = 0.025
        static let extremeNeutralChroma = 0.07
        static let extremeLightness = 0.90
        static let extremeDarkness = 0.14
        static let minimumSeamChroma = 0.05
        static let maximumSeamChroma = 0.18
        static let tintMinimumLuminance = 0.18
        static let tintMaximumLuminance = 0.46
        static let tintLuminanceScale = 0.82
        static let tintComponentMaximum = 0.76
        static let tintNeutralBlend = 0.10
    }

    private let cache = KLPaletteCache()
    private let histogram = KLPerceptualHistogram()
    private let configuration: KLPaletteAnalysisConfiguration

    /// Creates an analyzer with an in-memory cache scoped to this instance.
    public init(configuration: KLPaletteAnalysisConfiguration = .standard) {
        self.configuration = configuration
    }

    /// Returns the bounded raster plan used to analyze an image.
    public func rasterPlan(for image: CGImage) -> KLPaletteRasterPlan {
        configuration.rasterPlan(for: image)
    }

    /// Analyzes the region that is visible under the request's crop configuration.
    public func analyze(_ request: KLPaletteRequest) -> KLAdaptivePalette {
        guard request.containerSize.width > 0,
              request.containerSize.height > 0,
              let pixels = rasterizedPixels(for: request.image) else {
            return .fallback
        }
        let key = cacheKey(for: request, pixels: pixels)
        if let cached = cache.value(for: key) { return cached }
        guard let palette = makePalette(for: request, pixels: pixels) else {
            return .fallback
        }
        cache.insert(palette, for: key)
        return palette
    }

    /// Returns a deterministic key containing the algorithm version, pixel digest, and crop signature.
    public func cacheKey(for request: KLPaletteRequest) -> String {
        guard let pixels = rasterizedPixels(for: request.image) else {
            return cacheKey(for: request, pixelDigest: "unavailable", rasterPlan: nil)
        }
        return cacheKey(for: request, pixels: pixels)
    }

    private func cacheKey(
        for request: KLPaletteRequest,
        pixels: KLRasterizedPixelBuffer
    ) -> String {
        cacheKey(
            for: request,
            pixelDigest: pixelDigest(pixels),
            rasterPlan: pixels.plan
        )
    }

    private func cacheKey(
        for request: KLPaletteRequest,
        pixelDigest: String,
        rasterPlan: KLPaletteRasterPlan?
    ) -> String {
        let size = request.containerSize
        let mode = request.contentMode == .aspectFill ? "fill" : "fit"
        let crop = "\(Int(size.width.rounded()))x\(Int(size.height.rounded())):\(mode):\(request.anchor.x):\(request.anchor.y)"
        let raster = rasterPlan.map { "\($0.rasterWidth)x\($0.rasterHeight)" }
            ?? "unavailable"
        return "klAdaptivePalette:\(Tuning.algorithmVersion):\(request.cacheID):\(crop):\(raster):\(pixelDigest)"
    }

    private func makePalette(
        for request: KLPaletteRequest,
        pixels: KLRasterizedPixelBuffer
    ) -> KLAdaptivePalette? {
        let sourceVisibleRect = visibleRect(for: request)
        let visibleRect = pixels.plan.rasterRect(forSourceRect: sourceVisibleRect)
        guard !visibleRect.isEmpty else { return nil }
        let samples = pixels.samples(in: visibleRect, alphaThreshold: Tuning.alphaThreshold)
        guard let edge = edgeColor(from: pixels, visibleRect: visibleRect), !samples.isEmpty else { return nil }
        let candidates = histogram.candidates(from: samples, maximumCount: Tuning.maximumCandidateCount)
        let source = cleanedSeamColor(edge)
        let tint = toneMappedTint(from: candidates.first?.color ?? source)
        let foreground = KLContrastPolicy.foreground(for: source)
        let runnerUp = candidates.dropFirst().first?.weight ?? 0
        let confidence = candidates.first.map { KLColor.clamp($0.weight - runnerUp * Tuning.confidenceRunnerUpWeight) } ?? 0
        return KLAdaptivePalette(rawEdgeColor: edge, sourceColor: source, candidates: candidates, confidence: confidence, tintColor: tint, lightBackground: source, lightForeground: foreground, darkBackground: source, darkForeground: foreground)
    }

    private func visibleRect(for request: KLPaletteRequest) -> CGRect {
        let imageSize = CGSize(width: request.image.width, height: request.image.height)
        guard imageSize.width > 0, imageSize.height > 0 else { return .zero }
        guard request.contentMode == .aspectFill else { return CGRect(origin: .zero, size: imageSize) }
        let scale = max(request.containerSize.width / imageSize.width, request.containerSize.height / imageSize.height)
        let size = CGSize(width: min(imageSize.width, request.containerSize.width / scale), height: min(imageSize.height, request.containerSize.height / scale))
        return CGRect(x: max((imageSize.width - size.width) * request.anchor.x, 0), y: max((imageSize.height - size.height) * request.anchor.y, 0), width: size.width, height: size.height)
    }

    private func edgeColor(
        from pixels: KLRasterizedPixelBuffer,
        visibleRect: CGRect
    ) -> KLColor? {
        let height = min(max(visibleRect.height * Tuning.edgeFraction, Tuning.minimumEdgeHeight), visibleRect.height)
        let edgeRect = CGRect(x: visibleRect.minX, y: visibleRect.maxY - height, width: visibleRect.width, height: height)
        let edgeSamples = pixels.samples(in: edgeRect, alphaThreshold: Tuning.alphaThreshold)
        guard let representative = medianRepresentative(in: edgeSamples) else { return nil }

        let distances = edgeSamples.map {
            sqrt(squaredDistance($0.color, representative.color))
        }
        let textureSpread = percentile(
            distances,
            fraction: Tuning.naturalEdgeTexturePercentile
        )
        guard textureSpread > Tuning.naturalEdgeTextureThreshold else {
            return representative.color
        }

        let center = KLColorScience.oklch(from: representative.color)
        let ranked: [(sample: KLSample, score: Double)]
        if center.chroma < Tuning.neutralEdgeChromaThreshold {
            let chromaLimit = max(
                Tuning.neutralFamilyMinimumChromaLimit,
                center.chroma + Tuning.neutralFamilyChromaMargin
            )
            ranked = edgeSamples.compactMap { sample in
                let color = KLColorScience.oklch(from: sample.color)
                guard color.chroma <= chromaLimit else { return nil }
                return (
                    sample,
                    color.lightness - color.chroma * Tuning.neutralFamilyChromaPenalty
                )
            }
        } else {
            ranked = edgeSamples.compactMap { sample in
                let color = KLColorScience.oklch(from: sample.color)
                guard circularHueDistance(color.hue, center.hue)
                        <= Tuning.chromaticFamilyHueTolerance else {
                    return nil
                }
                return (
                    sample,
                    color.lightness + color.chroma * Tuning.chromaticFamilyChromaWeight
                )
            }
        }

        guard !ranked.isEmpty else { return representative.color }
        let sorted = ranked.sorted { $0.score < $1.score }
        return sorted[percentileIndex(
            count: sorted.count,
            fraction: Tuning.cleanEdgeSelectionPercentile
        )].sample.color
    }

    private func medianRepresentative(in samples: [KLSample]) -> KLSample? {
        guard !samples.isEmpty else { return nil }
        let center = KLColor(
            red: median(samples.map(\.color.red)),
            green: median(samples.map(\.color.green)),
            blue: median(samples.map(\.color.blue))
        )
        return samples.min {
            squaredDistance($0.color, center) < squaredDistance($1.color, center)
        }
    }

    private func median(_ values: [Double]) -> Double {
        let sorted = values.sorted(); let middle = sorted.count / 2
        return sorted.count.isMultiple(of: 2) ? (sorted[middle - 1] + sorted[middle]) / 2 : sorted[middle]
    }

    private func squaredDistance(_ lhs: KLColor, _ rhs: KLColor) -> Double {
        pow(lhs.red - rhs.red, 2) + pow(lhs.green - rhs.green, 2) + pow(lhs.blue - rhs.blue, 2)
    }

    private func circularHueDistance(_ lhs: Double, _ rhs: Double) -> Double {
        let distance = abs(lhs - rhs)
        return min(distance, .pi * 2 - distance)
    }

    private func percentile(_ values: [Double], fraction: Double) -> Double {
        guard !values.isEmpty else { return 0 }
        let sorted = values.sorted()
        return sorted[percentileIndex(count: sorted.count, fraction: fraction)]
    }

    private func percentileIndex(count: Int, fraction: Double) -> Int {
        guard count > 1 else { return 0 }
        return min(
            max(Int((Double(count - 1) * fraction).rounded()), 0),
            count - 1
        )
    }

    private func cleanedSeamColor(_ color: KLColor) -> KLColor {
        let perceptual = KLColorScience.oklch(from: color)
        let extremeNeutral = (perceptual.lightness >= Tuning.extremeLightness || perceptual.lightness <= Tuning.extremeDarkness) && perceptual.chroma < Tuning.extremeNeutralChroma
        let chroma = perceptual.chroma < Tuning.seamNeutralChroma || extremeNeutral ? 0 : min(max(perceptual.chroma, Tuning.minimumSeamChroma), Tuning.maximumSeamChroma)
        return KLColorScience.rgb(from: KLOKLCHColor(lightness: perceptual.lightness, chroma: chroma, hue: perceptual.hue))
    }

    private func toneMappedTint(from color: KLColor) -> KLColor {
        let luminance = max(color.relativeLuminance, 0.001)
        let target = min(max(luminance * Tuning.tintLuminanceScale, Tuning.tintMinimumLuminance), Tuning.tintMaximumLuminance)
        let scale = target / luminance
        let mapped = KLColor(red: min(color.red * scale, Tuning.tintComponentMaximum), green: min(color.green * scale, Tuning.tintComponentMaximum), blue: min(color.blue * scale, Tuning.tintComponentMaximum))
        let neutral = KLColor(red: 0.20, green: 0.195, blue: 0.19)
        let blend = Tuning.tintNeutralBlend
        return KLColor(red: mapped.red * (1 - blend) + neutral.red * blend, green: mapped.green * (1 - blend) + neutral.green * blend, blue: mapped.blue * (1 - blend) + neutral.blue * blend)
    }

    private func pixelDigest(_ pixels: KLRasterizedPixelBuffer) -> String {
        var digest = Tuning.fnvOffsetBasis
        for byte in pixels.bytes {
            digest ^= UInt64(byte); digest &*= Tuning.fnvPrime
        }
        digest ^= UInt64(pixels.bytes.count)
        return String(digest, radix: 16)
    }

    private func rasterizedPixels(for image: CGImage) -> KLRasterizedPixelBuffer? {
        KLRasterizedPixelBuffer(
            image: image,
            plan: configuration.rasterPlan(for: image)
        )
    }
}
