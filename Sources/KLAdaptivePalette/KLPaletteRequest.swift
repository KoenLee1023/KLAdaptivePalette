import CoreGraphics

/// The scaling rule used to determine which image region is visible.
public enum KLImageContentMode: Sendable {
    /// Crop the image to fill the container.
    case aspectFill
    /// Show the complete image inside the container.
    case aspectFit
}

/// Input for a single adaptive palette analysis.
public struct KLPaletteRequest {
    /// The image whose visible region will be analyzed.
    public let image: CGImage
    /// A host-provided identifier that scopes cache entries.
    public let cacheID: String
    /// The dimensions of the image's display container.
    public let containerSize: CGSize
    /// The image scaling rule used by the host.
    public let contentMode: KLImageContentMode
    /// The normalized crop anchor used by aspect-fill display.
    public let anchor: CGPoint

    /// Creates an analysis request.
    public init(
        image: CGImage,
        cacheID: String,
        containerSize: CGSize,
        contentMode: KLImageContentMode = .aspectFill,
        anchor: CGPoint = CGPoint(x: 0.5, y: 0.5)
    ) {
        self.image = image
        self.cacheID = cacheID
        self.containerSize = containerSize
        self.contentMode = contentMode
        self.anchor = CGPoint(x: KLColor.clamp(anchor.x), y: KLColor.clamp(anchor.y))
    }
}
