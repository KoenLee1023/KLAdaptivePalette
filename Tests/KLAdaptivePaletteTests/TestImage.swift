import CoreGraphics
import Foundation
import Testing

enum TestImage {
    static func solid(red: Double, green: Double, blue: Double, alpha: Double = 1) throws -> CGImage {
        let components = (byte(red), byte(green), byte(blue), byte(alpha))
        return try image(width: 32, height: 32) { _, _ in components }
    }

    static func horizontalSplit() throws -> CGImage {
        try image(width: 64, height: 32) { x, _ in
            x < 32 ? (255, 191, 20, 255) : (240, 56, 41, 255)
        }
    }

    static func transparentEdgeWithOpaqueBottom() throws -> CGImage {
        try image(width: 32, height: 32) { _, y in
            y < 28 ? (255, 255, 255, 0) : (12, 230, 65, 255)
        }
    }

    static func threeColumnStrip() throws -> CGImage {
        try image(width: 120, height: 30) { x, _ in
            switch x {
            case 0..<40: (235, 40, 30, 255)
            case 40..<80: (25, 210, 70, 255)
            default: (35, 70, 235, 255)
            }
        }
    }

    static func flatArtworkEdge() throws -> CGImage {
        try image(width: 120, height: 120) { _, _ in
            (242, 64, 143, 255)
        }
    }

    static func texturedCloudEdge() throws -> CGImage {
        try image(width: 120, height: 120) { x, y in
            guard y >= 114 else { return (51, 110, 179, 255) }
            return x < 84
                ? (140, 145, 148, 255)
                : (232, 237, 240, 255)
        }
    }

    static func texturedGrassEdge() throws -> CGImage {
        try image(width: 120, height: 120) { x, y in
            guard y >= 114 else { return (59, 120, 64, 255) }
            return x < 84
                ? (87, 97, 51, 255)
                : (61, 153, 71, 255)
        }
    }

    static func tinySaturatedArtifacts() throws -> CGImage {
        try image(width: 20, height: 20) { x, y in
            let isArtifact = y == 10 && (9...11).contains(x)
            return isArtifact
                ? (255, 0, 204, 255)
                : (143, 148, 140, 255)
        }
    }

    static func largeSolid(width: Int = 2_048, height: Int = 1_536) throws -> CGImage {
        try image(width: width, height: height) { _, _ in
            (31, 112, 184, 255)
        }
    }

    static func largeThreeColumnStrip() throws -> CGImage {
        try image(width: 1_200, height: 300) { x, _ in
            switch x {
            case 0..<400: (235, 40, 30, 255)
            case 400..<800: (25, 210, 70, 255)
            default: (35, 70, 235, 255)
            }
        }
    }

    static func largeTransparentRedCheckerboard() throws -> CGImage {
        try image(width: 1_024, height: 1_024) { x, y in
            let alpha: UInt8 = (x + y).isMultiple(of: 2) ? 255 : 0
            return (255, 0, 0, alpha)
        }
    }

    static func image(
        width: Int,
        height: Int,
        pixel: (Int, Int) -> (UInt8, UInt8, UInt8, UInt8)
    ) throws -> CGImage {
        var bytes = [UInt8]()
        bytes.reserveCapacity(width * height * 4)
        for y in 0..<height {
            for x in 0..<width {
                let rgba = pixel(x, y)
                bytes.append(rgba.0)
                bytes.append(rgba.1)
                bytes.append(rgba.2)
                bytes.append(rgba.3)
            }
        }

        let provider = try #require(CGDataProvider(data: Data(bytes) as CFData))
        return try #require(CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        ))
    }

    private static func byte(_ component: Double) -> UInt8 {
        UInt8((min(max(component, 0), 1) * 255).rounded())
    }
}
