import CoreGraphics

/// A ranked color candidate discovered in the visible image region.
public struct KLPaletteCandidate: Hashable, Sendable {
    /// The representative candidate color.
    public let color: KLColor
    /// The deterministic visual-usefulness score used for ranking.
    public let weight: Double
    /// The candidate's normalized position inside the visible image region.
    public let position: CGPoint

    /// Creates a palette candidate.
    public init(color: KLColor, weight: Double, position: CGPoint) {
        self.color = color
        self.weight = weight
        self.position = position
    }
}

/// The complete palette derived from a visible image region.
public struct KLAdaptivePalette: Sendable {
    /// The unmodified representative color touching the visible lower edge.
    public let rawEdgeColor: KLColor
    /// The normalized edge color used as the palette source.
    public let sourceColor: KLColor
    /// Distinct, ranked colors from the visible image region.
    public let candidates: [KLPaletteCandidate]
    /// The analyzer's confidence in the candidate ranking, in `0...1`.
    public let confidence: Double
    /// A toned accent derived from the strongest candidate.
    public let tintColor: KLColor
    /// A readable surface for light host appearances.
    public let lightBackground: KLColor
    /// Foreground selected for `lightBackground` by actual luminance.
    public let lightForeground: KLColor
    /// A readable surface for dark host appearances.
    public let darkBackground: KLColor
    /// Foreground selected for `darkBackground` by actual luminance.
    public let darkForeground: KLColor

    /// Creates a palette from resolved colors.
    public init(
        rawEdgeColor: KLColor,
        sourceColor: KLColor,
        candidates: [KLPaletteCandidate],
        confidence: Double,
        tintColor: KLColor,
        lightBackground: KLColor,
        lightForeground: KLColor,
        darkBackground: KLColor,
        darkForeground: KLColor
    ) {
        self.rawEdgeColor = rawEdgeColor
        self.sourceColor = sourceColor
        self.candidates = candidates
        self.confidence = KLColor.clamp(confidence)
        self.tintColor = tintColor
        self.lightBackground = lightBackground
        self.lightForeground = lightForeground
        self.darkBackground = darkBackground
        self.darkForeground = darkForeground
    }

    static let fallback = KLAdaptivePalette(
        rawEdgeColor: KLColor(red: 0.16, green: 0.15, blue: 0.14),
        sourceColor: KLColor(red: 0.16, green: 0.15, blue: 0.14),
        candidates: [],
        confidence: 0,
        tintColor: KLColor(red: 0.20, green: 0.195, blue: 0.19),
        lightBackground: KLColor(red: 0.075, green: 0.073, blue: 0.070),
        lightForeground: KLColor(red: 0.94, green: 0.94, blue: 0.93),
        darkBackground: KLColor(red: 0.075, green: 0.073, blue: 0.070),
        darkForeground: KLColor(red: 0.94, green: 0.94, blue: 0.93)
    )
}

/// Selects a foreground by comparing contrast against the real background.
public enum KLContrastPolicy {
    /// Returns the neutral foreground with the greater WCAG contrast ratio.
    public static func foreground(for background: KLColor) -> KLColor {
        let dark = KLColor(red: 0.04, green: 0.04, blue: 0.04)
        let light = KLColor(red: 0.97, green: 0.97, blue: 0.97)
        return KLColorScience.contrast(background, dark) >= KLColorScience.contrast(background, light)
            ? dark
            : light
    }
}
