# API

`KLAdaptivePalette` 从 `CGImage` 的可见区域生成调色板，用于背景和前景色。它不负责加载或持有图片。

`KLPaletteRequest` 接收图片、`cacheID`、容器尺寸、`KLImageContentMode` 和裁剪锚点。`aspectFill`分析可见裁剪区域，`aspectFit`分析完整图片。

`KLPaletteAnalyzer` 返回`KLAdaptivePalette`，其中包含`KLPaletteCandidate`、`confidence`、来源色、色调，以及浅色和深色背景/前景色。`KLContrastPolicy.foreground(for:)`按真实对比度选择前景色，不依赖昼夜模式。

`KLPaletteAnalysisConfiguration`限制最大边长和总像素数。`rasterPlan(for:)`报告光栅尺寸和 RGBA 内存需求。`KLPerceptualColor.interpolate(from:to:amount:)`使用 OKLCH 插值，`normalizedControlSurface(_:)`抑制脏色和过高饱和度。

缓存键由`cacheID`、像素、容器几何、显示模式和锚点决定。图片不变时不会重复扫描。

