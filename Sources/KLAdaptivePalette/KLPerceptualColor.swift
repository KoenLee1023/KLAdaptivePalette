/// Perceptual color operations for transitions between palette surfaces.
public enum KLPerceptualColor {
    /// Interpolates colors in OKLCH along the shortest hue path.
    ///
    /// Achromatic endpoints borrow the chromatic endpoint's hue. Alpha is
    /// interpolated linearly, and `amount` is clamped to `0...1`.
    public static func interpolate(
        from start: KLColor,
        to end: KLColor,
        amount: Double
    ) -> KLColor {
        KLColorScience.interpolate(from: start, to: end, amount: amount)
    }

    /// Normalizes a sampled control surface without changing its lightness or hue.
    ///
    /// Nearly neutral samples become fully neutral. Chromatic samples keep a
    /// modest minimum chroma and cap highly saturated colors so foreground
    /// contrast remains stable.
    public static func normalizedControlSurface(_ color: KLColor) -> KLColor {
        let components = KLColorScience.oklch(from: color)
        let chroma: Double
        if components.chroma < 0.012 {
            chroma = 0
        } else {
            chroma = min(max(components.chroma, 0.035), 0.18)
        }
        let normalized = KLColorScience.rgb(from: KLOKLCHColor(
            lightness: components.lightness,
            chroma: chroma,
            hue: components.hue
        ))
        return KLColor(
            red: normalized.red,
            green: normalized.green,
            blue: normalized.blue,
            alpha: color.alpha
        )
    }
}
