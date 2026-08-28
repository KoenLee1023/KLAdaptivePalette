# 更新日志

## 0.1.2

- 分析结果的内存缓存改为有容量上限的 LRU 策略。

## 0.1.1

- 恢复带纹理的中性和彩色边缘选色，同时保留平坦图像的准确颜色。
- 使用 `KLPaletteAnalysisConfiguration` 限制分析栅格的尺寸和像素数。
- 通过 `KLPerceptualColor` 提供 OKLCH 插值 API。

## 0.1.0

- 首次公开发布：包含可见裁切调色、确定性缓存、测试、DocC 和演示程序。
