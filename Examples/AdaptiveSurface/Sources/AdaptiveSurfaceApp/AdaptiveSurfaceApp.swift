import CoreGraphics
import KLAdaptivePalette
import SwiftUI

@main
struct AdaptiveSurfaceApp: App {
    var body: some Scene {
        WindowGroup("Adaptive Surface") { AdaptiveSurfaceView().frame(minWidth: 640, minHeight: 460) }
    }
}

private struct AdaptiveSurfaceView: View {
    @State private var isLightImage = false
    private let analyzer = KLPaletteAnalyzer()

    var body: some View {
        let palette = analyzer.analyze(KLPaletteRequest(image: DemoImage.make(light: isLightImage), cacheID: isLightImage ? "light" : "dark", containerSize: CGSize(width: 480, height: 260)))
        VStack(alignment: .leading, spacing: 22) {
            Toggle("Use light media", isOn: $isLightImage)
            Text("Adaptive Surface").font(.largeTitle.bold())
            HStack(spacing: 18) {
                SurfaceCard(title: "Light card", background: palette.lightBackground, foreground: palette.lightForeground)
                SurfaceCard(title: "Dark card", background: palette.darkBackground, foreground: palette.darkForeground)
            }
            Text("Both cards choose their foreground from the palette background's measured luminance, not from the system appearance.")
                .foregroundStyle(.secondary)
        }
        .padding(28)
    }
}

private struct SurfaceCard: View {
    let title: String; let background: KLColor; let foreground: KLColor
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title).font(.title2.bold())
            Text("Readable content on a media-derived surface.")
            Button("Continue") {}
                .buttonStyle(.borderedProminent)
        }
        .foregroundStyle(Color(foreground))
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 180, alignment: .leading)
        .background(Color(background), in: RoundedRectangle(cornerRadius: 20))
    }
}

private enum DemoImage {
    static func make(light: Bool) -> CGImage {
        let component: UInt8 = light ? 245 : 18
        let bytes = [UInt8](repeating: component, count: 64 * 64 * 4).enumerated().map { index, value in index.isMultiple(of: 4) || (index - 1).isMultiple(of: 4) || (index - 2).isMultiple(of: 4) ? value : 255 }
        let provider = CGDataProvider(data: Data(bytes) as CFData)!
        return CGImage(width: 64, height: 64, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: 256, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue), provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
    }
}

private extension Color {
    init(_ color: KLColor) { self.init(red: color.red, green: color.green, blue: color.blue, opacity: color.alpha) }
}
