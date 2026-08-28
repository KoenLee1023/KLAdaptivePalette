import CoreGraphics
import Foundation

struct KLRasterizedPixelBuffer {
    let plan: KLPaletteRasterPlan
    let bytes: [UInt8]

    var width: Int { plan.rasterWidth }
    var height: Int { plan.rasterHeight }

    init?(image: CGImage, plan: KLPaletteRasterPlan) {
        guard image.width == plan.sourceWidth,
              image.height == plan.sourceHeight else {
            return nil
        }
        var pixels = [UInt8](repeating: 0, count: plan.rasterByteCount)
        guard let context = CGContext(
            data: &pixels,
            width: plan.rasterWidth,
            height: plan.rasterHeight,
            bitsPerComponent: 8,
            bytesPerRow: plan.rasterWidth * Self.rgbaComponentCount,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        context.interpolationQuality = .medium
        context.draw(
            image,
            in: CGRect(
                x: 0,
                y: 0,
                width: plan.rasterWidth,
                height: plan.rasterHeight
            )
        )
        self.plan = plan
        bytes = pixels
    }

    func samples(in rect: CGRect, alphaThreshold: UInt8) -> [KLSample] {
        let minX = max(Int(floor(rect.minX)), 0)
        let maxX = min(Int(ceil(rect.maxX)), width)
        let minY = max(Int(floor(rect.minY)), 0)
        let maxY = min(Int(ceil(rect.maxY)), height)
        guard minX < maxX, minY < maxY else { return [] }

        var result: [KLSample] = []
        result.reserveCapacity((maxX - minX) * (maxY - minY))
        for y in minY..<maxY {
            for x in minX..<maxX {
                let offset = (y * width + x) * Self.rgbaComponentCount
                let alpha = bytes[offset + Self.alphaComponentOffset]
                guard alpha > alphaThreshold else { continue }
                let unpremultiply = Self.componentMaximum / Double(alpha)
                let position = CGPoint(
                    x: rect.width <= 1
                        ? Self.centerPosition
                        : (Double(x) - rect.minX) / rect.width,
                    y: rect.height <= 1
                        ? Self.centerPosition
                        : (Double(y) - rect.minY) / rect.height
                )
                result.append(KLSample(
                    color: KLColor(
                        red: Double(bytes[offset]) * unpremultiply / Self.componentMaximum,
                        green: Double(bytes[offset + 1]) * unpremultiply / Self.componentMaximum,
                        blue: Double(bytes[offset + 2]) * unpremultiply / Self.componentMaximum,
                        alpha: Double(alpha) / Self.componentMaximum
                    ),
                    position: position
                ))
            }
        }
        return result
    }

    private static let rgbaComponentCount = 4
    private static let alphaComponentOffset = 3
    private static let componentMaximum = 255.0
    private static let centerPosition = 0.5
}
