# API

`KLAdaptivePalette` 從 `CGImage` 的可見區域產生調色盤，用於背景與前景色。不負責載入或持有圖片。

`KLPaletteRequest` 接收圖片、`cacheID`、容器尺寸、`KLImageContentMode` 與裁切錨點。`aspectFill`分析可見裁切區域，`aspectFit`分析完整圖片。

`KLPaletteAnalyzer` 回傳`KLAdaptivePalette`，包含`KLPaletteCandidate`、`confidence`、來源色、色調，以及淺色與深色背景/前景色。`KLContrastPolicy.foreground(for:)`依實際對比度選擇前景色，不依賴晝夜模式。

`KLPaletteAnalysisConfiguration`限制最大邊長與總像素數。`rasterPlan(for:)`回報光柵尺寸與 RGBA 記憶體需求。`KLPerceptualColor.interpolate(from:to:amount:)`使用 OKLCH 插值，`normalizedControlSurface(_:)`抑制髒色與過高飽和度。

快取鍵由`cacheID`、像素、容器幾何、顯示模式與錨點決定。圖片不變時不會重複掃描。

