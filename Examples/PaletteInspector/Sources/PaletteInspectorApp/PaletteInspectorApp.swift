import CoreGraphics
import KLAdaptivePalette
import SwiftUI

@main
struct PaletteInspectorApp: App {
    var body: some Scene {
        WindowGroup("Palette Inspector") {
            PaletteInspectorView()
                .frame(minWidth: 720, minHeight: 620)
        }
    }
}

private struct PaletteInspectorView: View {
    @State private var contentMode: KLImageContentMode = .aspectFill
    @State private var aspectRatio = 1.0
    @State private var anchorX = 0.5
    @State private var anchorY = 0.5

    private let analyzer = KLPaletteAnalyzer()
    private let image = DemoImage.strip()

    private var request: KLPaletteRequest {
        KLPaletteRequest(
            image: image,
            cacheID: "palette-inspector-strip",
            containerSize: CGSize(width: 360 * aspectRatio, height: 360),
            contentMode: contentMode,
            anchor: CGPoint(x: anchorX, y: anchorY)
        )
    }

    var body: some View {
        let palette = analyzer.analyze(request)
        VStack(alignment: .leading, spacing: 18) {
            Text("Palette Inspector")
                .font(.largeTitle.bold())
            HStack(alignment: .top, spacing: 24) {
                VStack(alignment: .leading) {
                    Text("Source image").font(.headline)
                    Image(decorative: image, scale: 1)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 150)
                }
                VStack(alignment: .leading) {
                    Text("Visible crop").font(.headline)
                    Image(decorative: image, scale: 1)
                        .resizable()
                        .modifier(ImageCropMode(mode: contentMode))
                        .frame(width: 300, height: 150)
                        .clipped()
                }
            }
            Picker("Content mode", selection: $contentMode) {
                Text("Aspect fill").tag(KLImageContentMode.aspectFill)
                Text("Aspect fit").tag(KLImageContentMode.aspectFit)
            }
            .pickerStyle(.segmented)
            HStack {
                Slider(value: $aspectRatio, in: 0.5...2) { Text("Container ratio") }
                Text(String(format: "%.2f", aspectRatio)).monospacedDigit()
            }
            HStack {
                Slider(value: $anchorX, in: 0...1) { Text("Horizontal anchor") }
                Slider(value: $anchorY, in: 0...1) { Text("Vertical anchor") }
            }
            HStack(spacing: 12) {
                ForEach(Array(palette.candidates.enumerated()), id: \.offset) { _, candidate in
                    VStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8).fill(Color(candidate.color)).frame(width: 82, height: 40)
                        Text(String(format: "%.3f", candidate.weight)).font(.caption.monospaced())
                    }
                }
            }
            LabeledContent("Confidence", value: String(format: "%.3f", palette.confidence))
            LabeledContent("Cache key", value: analyzer.cacheKey(for: request))
                .font(.caption.monospaced())
        }
        .padding(28)
    }
}

private struct ImageCropMode: ViewModifier {
    let mode: KLImageContentMode
    func body(content: Content) -> some View {
        switch mode {
        case .aspectFill: content.scaledToFill()
        case .aspectFit: content.scaledToFit()
        }
    }
}

private enum DemoImage {
    static func strip() -> CGImage {
        let width = 300; let height = 120
        let colors: [(UInt8, UInt8, UInt8)] = [(236, 58, 52), (34, 204, 92), (46, 88, 232)]
        var bytes = [UInt8]()
        for _ in 0..<height { for x in 0..<width {
            let color = colors[min(x * colors.count / width, colors.count - 1)]
            bytes += [color.0, color.1, color.2, 255]
        } }
        let provider = CGDataProvider(data: Data(bytes) as CFData)!
        return CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue), provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
    }
}

private extension Color {
    init(_ color: KLColor) { self.init(red: color.red, green: color.green, blue: color.blue, opacity: color.alpha) }
}
