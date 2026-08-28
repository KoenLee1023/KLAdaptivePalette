import Foundation

struct KLOKLCHColor: Sendable {
    let lightness: Double
    let chroma: Double
    let hue: Double
}

enum KLColorScience {
    private static let achromaticChromaThreshold = 0.002

    static func oklch(from color: KLColor) -> KLOKLCHColor {
        let red = linearize(color.red)
        let green = linearize(color.green)
        let blue = linearize(color.blue)
        let l = 0.4122214708 * red + 0.5363325363 * green + 0.0514459929 * blue
        let m = 0.2119034982 * red + 0.6806995451 * green + 0.1073969566 * blue
        let s = 0.0883024619 * red + 0.2817188376 * green + 0.6299787005 * blue
        let lRoot = cbrt(l)
        let mRoot = cbrt(m)
        let sRoot = cbrt(s)
        let lightness = 0.2104542553 * lRoot + 0.7936177850 * mRoot - 0.0040720468 * sRoot
        let a = 1.9779984951 * lRoot - 2.4285922050 * mRoot + 0.4505937099 * sRoot
        let b = 0.0259040371 * lRoot + 0.7827717662 * mRoot - 0.8086757660 * sRoot
        return KLOKLCHColor(lightness: lightness, chroma: hypot(a, b), hue: normalizedHue(atan2(b, a)))
    }

    static func rgb(from color: KLOKLCHColor) -> KLColor {
        let a = color.chroma * cos(color.hue)
        let b = color.chroma * sin(color.hue)
        let lRoot = color.lightness + 0.3963377774 * a + 0.2158037573 * b
        let mRoot = color.lightness - 0.1055613458 * a - 0.0638541728 * b
        let sRoot = color.lightness - 0.0894841775 * a - 1.2914855480 * b
        let l = lRoot * lRoot * lRoot
        let m = mRoot * mRoot * mRoot
        let s = sRoot * sRoot * sRoot
        return KLColor(
            red: encode(4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s),
            green: encode(-1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s),
            blue: encode(-0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s)
        )
    }

    static func interpolate(
        from start: KLColor,
        to end: KLColor,
        amount: Double
    ) -> KLColor {
        let progress = KLColor.clamp(amount)
        guard progress > 0 else { return start }
        guard progress < 1 else { return end }

        var lhs = oklch(from: start)
        var rhs = oklch(from: end)
        if lhs.chroma < Self.achromaticChromaThreshold,
           rhs.chroma >= Self.achromaticChromaThreshold {
            lhs = KLOKLCHColor(
                lightness: lhs.lightness,
                chroma: lhs.chroma,
                hue: rhs.hue
            )
        } else if rhs.chroma < Self.achromaticChromaThreshold,
                  lhs.chroma >= Self.achromaticChromaThreshold {
            rhs = KLOKLCHColor(
                lightness: rhs.lightness,
                chroma: rhs.chroma,
                hue: lhs.hue
            )
        }

        var hueDelta = rhs.hue - lhs.hue
        if hueDelta > .pi { hueDelta -= .pi * 2 }
        if hueDelta < -.pi { hueDelta += .pi * 2 }
        let rgb = rgb(from: KLOKLCHColor(
            lightness: lhs.lightness + (rhs.lightness - lhs.lightness) * progress,
            chroma: lhs.chroma + (rhs.chroma - lhs.chroma) * progress,
            hue: normalizedHue(lhs.hue + hueDelta * progress)
        ))
        return KLColor(
            red: rgb.red,
            green: rgb.green,
            blue: rgb.blue,
            alpha: start.alpha + (end.alpha - start.alpha) * progress
        )
    }

    static func contrast(_ lhs: KLColor, _ rhs: KLColor) -> Double {
        (max(lhs.relativeLuminance, rhs.relativeLuminance) + 0.05)
            / (min(lhs.relativeLuminance, rhs.relativeLuminance) + 0.05)
    }

    static func linearize(_ channel: Double) -> Double {
        channel <= 0.04045 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
    }

    private static func encode(_ channel: Double) -> Double {
        channel <= 0.0031308 ? channel * 12.92 : 1.055 * pow(channel, 1 / 2.4) - 0.055
    }

    private static func normalizedHue(_ hue: Double) -> Double {
        let circle = Double.pi * 2
        let value = hue.truncatingRemainder(dividingBy: circle)
        return value >= 0 ? value : value + circle
    }
}
