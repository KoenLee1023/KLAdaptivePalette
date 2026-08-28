import CoreGraphics
import Testing
@testable import KLAdaptivePalette

@Suite("KLAdaptivePalette")
struct KLAdaptivePaletteTests {
    @Test func `white image keeps dark foreground in dark system appearance`() throws {
        let image = try TestImage.solid(red: 1, green: 1, blue: 1)
        let palette = KLPaletteAnalyzer().analyze(
            KLPaletteRequest(
                image: image,
                cacheID: "white",
                containerSize: CGSize(width: 170, height: 170)
            )
        )

        #expect(palette.darkForeground.relativeLuminance < 0.25)
    }

    @Test func `cache key changes with visible crop`() throws {
        let image = try TestImage.horizontalSplit()
        let analyzer = KLPaletteAnalyzer()
        let square = KLPaletteRequest(
            image: image,
            cacheID: "split",
            containerSize: .init(width: 200, height: 200)
        )
        let banner = KLPaletteRequest(
            image: image,
            cacheID: "split",
            containerSize: .init(width: 400, height: 160)
        )

        #expect(analyzer.cacheKey(for: square) != analyzer.cacheKey(for: banner))
    }

    @Test func `black image keeps light foreground`() throws {
        let palette = KLPaletteAnalyzer().analyze(request(for: try TestImage.solid(red: 0, green: 0, blue: 0)))

        #expect(palette.darkForeground.relativeLuminance > 0.75)
        #expect(palette.darkBackground.relativeLuminance < 0.08)
    }

    @Test func `neutral gray remains neutral`() throws {
        let palette = KLPaletteAnalyzer().analyze(request(for: try TestImage.solid(red: 0.5, green: 0.5, blue: 0.5)))

        #expect(abs(palette.sourceColor.red - palette.sourceColor.green) < 0.02)
        #expect(abs(palette.sourceColor.green - palette.sourceColor.blue) < 0.02)
    }

    @Test func `transparent pixels do not affect edge analysis`() throws {
        let image = try TestImage.transparentEdgeWithOpaqueBottom()
        let palette = KLPaletteAnalyzer().analyze(request(for: image))

        #expect(palette.rawEdgeColor.green > 0.75)
        #expect(palette.rawEdgeColor.red < 0.2)
    }

    @Test func `high saturation split keeps distinct candidates`() throws {
        let palette = KLPaletteAnalyzer().analyze(request(for: try TestImage.horizontalSplit()))

        #expect(palette.candidates.count >= 2)
        let first = palette.candidates[0].color
        let second = palette.candidates[1].color
        let componentDistance = abs(first.red - second.red)
            + abs(first.green - second.green)
            + abs(first.blue - second.blue)
        #expect(componentDistance > 0.2)
    }

    @Test func `aspect fill samples the visible crop`() throws {
        let image = try TestImage.threeColumnStrip()
        let palette = KLPaletteAnalyzer().analyze(
            KLPaletteRequest(
                image: image,
                cacheID: "strip",
                containerSize: CGSize(width: 100, height: 100),
                contentMode: .aspectFill
            )
        )

        #expect(palette.sourceColor.green > palette.sourceColor.red)
        #expect(palette.sourceColor.green > palette.sourceColor.blue)
    }

    @Test func `aspect fit samples the complete image`() throws {
        let image = try TestImage.threeColumnStrip()
        let palette = KLPaletteAnalyzer().analyze(
            KLPaletteRequest(
                image: image,
                cacheID: "strip",
                containerSize: CGSize(width: 100, height: 100),
                contentMode: .aspectFit
            )
        )

        #expect(palette.candidates.contains { $0.color.red > 0.75 })
        #expect(palette.candidates.contains { $0.color.blue > 0.75 })
    }

    @Test func `candidate ordering is deterministic`() throws {
        let analyzer = KLPaletteAnalyzer()
        let request = request(for: try TestImage.horizontalSplit())

        #expect(analyzer.analyze(request).candidates == analyzer.analyze(request).candidates)
    }

    @Test func `cache key is stable for equal input`() throws {
        let analyzer = KLPaletteAnalyzer()
        let request = request(for: try TestImage.horizontalSplit())

        #expect(analyzer.cacheKey(for: request) == analyzer.cacheKey(for: request))
    }

    @Test func `cache key changes when image pixels change`() throws {
        let analyzer = KLPaletteAnalyzer()
        let first = request(for: try TestImage.solid(red: 0.04, green: 0.08, blue: 0.12))
        let second = request(for: try TestImage.solid(red: 0.05, green: 0.08, blue: 0.12))

        #expect(analyzer.cacheKey(for: first) != analyzer.cacheKey(for: second))
    }

    @Test func `flat artwork keeps its exact sampled edge color`() throws {
        let palette = KLPaletteAnalyzer().analyze(
            request(for: try TestImage.flatArtworkEdge())
        )
        let expected = KLColor(
            red: 242.0 / 255,
            green: 64.0 / 255,
            blue: 143.0 / 255
        )

        #expect(colorDistance(palette.rawEdgeColor, expected) < 0.01)
    }

    @Test func `textured neutral edge selects a clean sampled cloud color`() throws {
        let palette = KLPaletteAnalyzer().analyze(
            request(for: try TestImage.texturedCloudEdge())
        )

        #expect(palette.rawEdgeColor.red > 0.88)
        #expect(palette.rawEdgeColor.green > 0.90)
        #expect(palette.rawEdgeColor.blue > 0.92)
        #expect(componentSpread(of: palette.rawEdgeColor) < 0.06)
    }

    @Test func `textured chromatic edge selects fresh grass from the same hue family`() throws {
        let palette = KLPaletteAnalyzer().analyze(
            request(for: try TestImage.texturedGrassEdge())
        )

        #expect(palette.rawEdgeColor.green > 0.55)
        #expect(palette.rawEdgeColor.green > palette.rawEdgeColor.red * 1.8)
        #expect(palette.rawEdgeColor.green > palette.rawEdgeColor.blue * 1.7)
    }

    @Test func `bounded raster keeps natural cloud and grass edge families`() throws {
        let analyzer = KLPaletteAnalyzer(configuration: KLPaletteAnalysisConfiguration(
            maximumRasterDimension: 48,
            maximumRasterPixelCount: 2_304
        ))
        let cloud = analyzer.analyze(
            request(for: try TestImage.texturedCloudEdge())
        ).rawEdgeColor
        let grass = analyzer.analyze(
            request(for: try TestImage.texturedGrassEdge())
        ).rawEdgeColor

        #expect(cloud.red > 0.80)
        #expect(cloud.green > 0.82)
        #expect(cloud.blue > 0.84)
        #expect(grass.green > grass.red * 1.5)
        #expect(grass.green > grass.blue * 1.4)
    }

    @Test func `tiny saturated artifacts do not replace the dominant candidate`() throws {
        let palette = KLPaletteAnalyzer().analyze(
            request(for: try TestImage.tinySaturatedArtifacts())
        )
        let candidate = try #require(palette.candidates.first?.color)

        #expect(componentSpread(of: candidate) < 0.12)
    }

    @Test func `large images receive a bounded analysis raster plan`() throws {
        let image = try TestImage.largeSolid()
        let configuration = KLPaletteAnalysisConfiguration(
            maximumRasterDimension: 512,
            maximumRasterPixelCount: 131_072
        )
        let plan = configuration.rasterPlan(for: image)

        #expect(plan.rasterWidth <= configuration.maximumRasterDimension)
        #expect(plan.rasterHeight <= configuration.maximumRasterDimension)
        #expect(plan.rasterPixelCount <= configuration.maximumRasterPixelCount)
        #expect(plan.rasterByteCount == plan.rasterPixelCount * 4)
        #expect(plan.rasterByteCount < plan.sourcePixelCount * 4)
    }

    @Test func `extreme aspect ratios still honor the pixel limit`() throws {
        let image = try TestImage.largeSolid(width: 10_000, height: 1)
        let configuration = KLPaletteAnalysisConfiguration(
            maximumRasterDimension: 512,
            maximumRasterPixelCount: 1
        )

        let plan = configuration.rasterPlan(for: image)

        #expect(plan.rasterWidth == 1)
        #expect(plan.rasterHeight == 1)
        #expect(plan.rasterPixelCount <= configuration.maximumRasterPixelCount)
    }

    @Test func `downsampled translucent pixels are returned as straight RGB`() throws {
        let image = try TestImage.largeTransparentRedCheckerboard()
        let configuration = KLPaletteAnalysisConfiguration(
            maximumRasterDimension: 16,
            maximumRasterPixelCount: 256
        )
        let pixels = try #require(
            KLRasterizedPixelBuffer(
                image: image,
                plan: configuration.rasterPlan(for: image)
            )
        )
        let samples = pixels.samples(
            in: CGRect(x: 0, y: 0, width: pixels.width, height: pixels.height),
            alphaThreshold: 0
        )
        let translucent = try #require(samples.first { $0.color.alpha < 0.99 })

        #expect(translucent.color.red > 0.95)
        #expect(translucent.color.green < 0.02)
        #expect(translucent.color.blue < 0.02)
    }

    @Test func `pixel buffer allocates only the bounded raster`() throws {
        let image = try TestImage.largeSolid()
        let configuration = KLPaletteAnalysisConfiguration(
            maximumRasterDimension: 256,
            maximumRasterPixelCount: 49_152
        )
        let plan = configuration.rasterPlan(for: image)
        let pixels = try #require(
            KLRasterizedPixelBuffer(image: image, plan: plan)
        )

        #expect(pixels.bytes.count == plan.rasterByteCount)
        #expect(pixels.bytes.count < plan.sourcePixelCount * 4)
    }

    @Test func `bounded raster preserves aspect fill crop semantics`() throws {
        let image = try TestImage.largeThreeColumnStrip()
        let analyzer = KLPaletteAnalyzer(configuration: KLPaletteAnalysisConfiguration(
            maximumRasterDimension: 120,
            maximumRasterPixelCount: 14_400
        ))
        let palette = analyzer.analyze(KLPaletteRequest(
            image: image,
            cacheID: "large-strip",
            containerSize: CGSize(width: 100, height: 100),
            contentMode: .aspectFill
        ))

        #expect(palette.sourceColor.green > palette.sourceColor.red)
        #expect(palette.sourceColor.green > palette.sourceColor.blue)
        let candidate = try #require(palette.candidates.first)
        #expect(candidate.position.x > 0.35)
        #expect(candidate.position.x < 0.65)
    }

    @Test func `perceptual interpolation borrows hue from a chromatic endpoint`() {
        let gray = KLColor(red: 0.5, green: 0.5, blue: 0.5)
        let green = KLColor(red: 0.10, green: 0.72, blue: 0.25)
        let midpoint = KLPerceptualColor.interpolate(
            from: gray,
            to: green,
            amount: 0.5
        )
        let perceptual = KLColorScience.oklch(from: midpoint)
        let greenHue = KLColorScience.oklch(from: green).hue

        #expect(abs(perceptual.hue - greenHue) < 0.08)
        #expect(perceptual.chroma > 0.04)
    }

    @Test func `perceptual interpolation clamps amount and blends alpha`() {
        let start = KLColor(red: 0.9, green: 0.1, blue: 0.2, alpha: 0.2)
        let end = KLColor(red: 0.1, green: 0.2, blue: 0.9, alpha: 0.8)

        #expect(KLPerceptualColor.interpolate(from: start, to: end, amount: -1) == start)
        #expect(KLPerceptualColor.interpolate(from: start, to: end, amount: 2) == end)
        #expect(abs(
            KLPerceptualColor.interpolate(from: start, to: end, amount: 0.5).alpha
                - 0.5
        ) < 0.001)
    }

    @Test func `control surface normalization removes near neutral tint and bounds chroma`() {
        let nearNeutral = KLColor(red: 0.51, green: 0.50, blue: 0.505)
        let saturated = KLColor(red: 0.05, green: 0.95, blue: 0.20)

        let neutral = KLPerceptualColor.normalizedControlSurface(nearNeutral)
        let bounded = KLPerceptualColor.normalizedControlSurface(saturated)
        let neutralComponents = KLColorScience.oklch(from: neutral)
        let boundedComponents = KLColorScience.oklch(from: bounded)

        #expect(neutralComponents.chroma < 0.002)
        #expect(boundedComponents.chroma <= 0.181)
        #expect(abs(boundedComponents.lightness - KLColorScience.oklch(from: saturated).lightness) < 0.002)
    }

    private func request(for image: CGImage) -> KLPaletteRequest {
        KLPaletteRequest(
            image: image,
            cacheID: "test-image",
            containerSize: CGSize(width: 170, height: 170)
        )
    }

    private func colorDistance(_ lhs: KLColor, _ rhs: KLColor) -> Double {
        sqrt(
            pow(lhs.red - rhs.red, 2)
                + pow(lhs.green - rhs.green, 2)
                + pow(lhs.blue - rhs.blue, 2)
        )
    }

    private func componentSpread(of color: KLColor) -> Double {
        let components = [color.red, color.green, color.blue]
        return (components.max() ?? 0) - (components.min() ?? 0)
    }
}
