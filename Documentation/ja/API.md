# API

`KLAdaptivePalette` は `CGImage` の表示領域から背景と前景に使うパレットを作ります。画像の読み込みや保持は行いません。

`KLPaletteRequest` は画像、`cacheID`、コンテナサイズ、`KLImageContentMode`、クロップアンカーを受け取ります。`aspectFill`は可視領域を、`aspectFit`は画像全体を解析します。

`KLPaletteAnalyzer` は`KLAdaptivePalette`を返します。結果には`KLPaletteCandidate`、`confidence`、ソース色、色調、明暗の背景と前景が含まれます。`KLContrastPolicy.foreground(for:)`は実際のコントラストで前景を選びます。

`KLPaletteAnalysisConfiguration`は最大辺と総ピクセル数を制限します。`rasterPlan(for:)`はラスタサイズと RGBA メモリ量を示します。`KLPerceptualColor.interpolate(from:to:amount:)`は OKLCH 補間、`normalizedControlSurface(_:)`は濁りと過剰な彩度の抑制に使います。

キャッシュキーは`cacheID`、ピクセル、ジオメトリ、表示モード、アンカーから決まります。画像が同じなら再解析しません。

