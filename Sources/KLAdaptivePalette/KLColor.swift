import Foundation

/// A platform-neutral sRGB color with normalized components.
public struct KLColor: Hashable, Sendable {
    /// The normalized red component.
    public let red: Double
    /// The normalized green component.
    public let green: Double
    /// The normalized blue component.
    public let blue: Double
    /// The normalized alpha component.
    public let alpha: Double

    /// Creates a color, clamping each component to `0...1`.
    public init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = Self.clamp(red)
        self.green = Self.clamp(green)
        self.blue = Self.clamp(blue)
        self.alpha = Self.clamp(alpha)
    }

    /// The WCAG relative luminance of the color's sRGB components.
    public var relativeLuminance: Double {
        0.2126 * KLColorScience.linearize(red)
            + 0.7152 * KLColorScience.linearize(green)
            + 0.0722 * KLColorScience.linearize(blue)
    }

    static func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}
