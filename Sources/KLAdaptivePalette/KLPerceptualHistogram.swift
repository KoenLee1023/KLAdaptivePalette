import CoreGraphics
import Foundation

struct KLSample: Sendable {
    let color: KLColor
    let position: CGPoint
}

struct KLPerceptualHistogram {
    private static let hueBinCount = 24
    private static let lightnessBinCount = 4
    private static let minimumLightness = 0.035
    private static let maximumHighlightLightness = 0.965
    private static let neutralChroma = 0.025
    private static let maximumReferenceChroma = 0.20
    private static let maximumReferenceDistance = 0.28
    private static let baseSampleWeight = 0.35
    private static let lowerRegionSampleBoost = 0.15
    private static let maximumNormalizedSpread = 0.58
    private static let coverageScoreWeight = 0.38
    private static let chromaScoreWeight = 0.24
    private static let coherenceScoreWeight = 0.14
    private static let lowerRegionScoreWeight = 0.10
    private static let saliencyScoreWeight = 0.14
    private static let luminanceSaliencyWeight = 0.12
    private static let extremeNeutralPenalty = 0.22
    private static let distinctCandidateDistance = 0.075
    private static let minimumCandidateSampleCount = 3
    private static let minimumCandidateCoverage = 0.04

    private struct Key: Hashable { let hue: Int; let lightness: Int }
    private struct Accumulator {
        var red = 0.0; var green = 0.0; var blue = 0.0; var x = 0.0; var y = 0.0
        var xSquared = 0.0; var ySquared = 0.0; var weight = 0.0; var count = 0
        mutating func add(_ sample: KLSample, weight: Double) {
            red += sample.color.red * weight; green += sample.color.green * weight; blue += sample.color.blue * weight
            x += sample.position.x; y += sample.position.y; xSquared += sample.position.x * sample.position.x
            ySquared += sample.position.y * sample.position.y; self.weight += weight; count += 1
        }
    }

    func candidates(from samples: [KLSample], maximumCount: Int) -> [KLPaletteCandidate] {
        guard !samples.isEmpty, maximumCount > 0 else { return [] }
        var buckets: [Key: Accumulator] = [:]
        var acceptedCount = 0
        for sample in samples {
            let perceptual = KLColorScience.oklch(from: sample.color)
            guard perceptual.lightness >= Self.minimumLightness else { continue }
            if perceptual.lightness > Self.maximumHighlightLightness, perceptual.chroma < Self.neutralChroma { continue }
            let hue = perceptual.chroma < Self.neutralChroma ? -1 : min(Int(perceptual.hue / (.pi * 2) * Double(Self.hueBinCount)), Self.hueBinCount - 1)
            let lightness = min(Int(perceptual.lightness * Double(Self.lightnessBinCount)), Self.lightnessBinCount - 1)
            let chromaWeight = min(perceptual.chroma / Self.maximumReferenceChroma, 1)
            buckets[Key(hue: hue, lightness: lightness), default: Accumulator()].add(sample, weight: Self.baseSampleWeight + chromaWeight + Self.lowerRegionSampleBoost * sample.position.y)
            acceptedCount += 1
        }
        guard acceptedCount > 0 else { return [] }
        let ranked = buckets.values.compactMap { accumulator -> KLPaletteCandidate? in
            guard accumulator.count >= Self.minimumCandidateSampleCount, accumulator.weight > 0 else { return nil }
            let coverage = Double(accumulator.count) / Double(samples.count)
            guard coverage >= Self.minimumCandidateCoverage else { return nil }
            let color = KLColor(red: accumulator.red / accumulator.weight, green: accumulator.green / accumulator.weight, blue: accumulator.blue / accumulator.weight)
            let perceptual = KLColorScience.oklch(from: color)
            let meanX = accumulator.x / Double(accumulator.count); let meanY = accumulator.y / Double(accumulator.count)
            let varianceX = max(accumulator.xSquared / Double(accumulator.count) - meanX * meanX, 0)
            let varianceY = max(accumulator.ySquared / Double(accumulator.count) - meanY * meanY, 0)
            let coherence = 1 - min(sqrt(varianceX + varianceY) / Self.maximumNormalizedSpread, 1)
            let chroma = min(perceptual.chroma / Self.maximumReferenceChroma, 1)
            let saliency = min((perceptual.chroma + abs(perceptual.lightness - 0.5) * Self.luminanceSaliencyWeight) / Self.maximumReferenceDistance, 1)
            let neutralPenalty = perceptual.chroma < Self.neutralChroma ? Self.extremeNeutralPenalty : 0
            let score = Self.coverageScoreWeight * coverage + Self.chromaScoreWeight * chroma + Self.coherenceScoreWeight * coherence + Self.lowerRegionScoreWeight * meanY + Self.saliencyScoreWeight * saliency - neutralPenalty
            return KLPaletteCandidate(color: color, weight: score, position: CGPoint(x: meanX, y: meanY))
        }.sorted { lhs, rhs in
            lhs.weight == rhs.weight ? lhs.color.red == rhs.color.red ? lhs.color.green == rhs.color.green ? lhs.color.blue < rhs.color.blue : lhs.color.green < rhs.color.green : lhs.color.red < rhs.color.red : lhs.weight > rhs.weight
        }
        var distinct: [KLPaletteCandidate] = []
        for candidate in ranked where !distinct.contains(where: { perceptualDistance($0.color, candidate.color) < Self.distinctCandidateDistance }) {
            distinct.append(candidate)
            if distinct.count == maximumCount { break }
        }
        return distinct
    }

    private func perceptualDistance(_ lhs: KLColor, _ rhs: KLColor) -> Double {
        let left = KLColorScience.oklch(from: lhs); let right = KLColorScience.oklch(from: rhs)
        let a = left.chroma * cos(left.hue) - right.chroma * cos(right.hue)
        let b = left.chroma * sin(left.hue) - right.chroma * sin(right.hue)
        return sqrt(pow(left.lightness - right.lightness, 2) + a * a + b * b)
    }
}
