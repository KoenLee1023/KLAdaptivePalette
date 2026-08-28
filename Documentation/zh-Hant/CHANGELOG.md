# 變更日誌

## 0.1.2

- 分析結果的記憶體快取改為有容量上限的 LRU 策略。

## 0.1.1

- 恢復帶有紋理的中性色與彩色邊緣選色，同時保留平坦影像的準確色彩。
- 使用 `KLPaletteAnalysisConfiguration` 限制分析光柵的尺寸和像素數。
- 透過 `KLPerceptualColor` 提供 OKLCH 插值 API。

## 0.1.0

- 首次公開發布：包含可見裁切調色、確定性快取、測試、DocC 和示範程式。
