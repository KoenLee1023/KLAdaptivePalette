# API

`KLAdaptivePalette`는 `CGImage`의 표시 영역에서 배경과 전경에 사용할 팔레트를 만듭니다. 이미지를 로드하거나 보관하지 않습니다.

`KLPaletteRequest`는 이미지, `cacheID`, 컨테이너 크기, `KLImageContentMode`, 크롭 앵커를 받습니다. `aspectFill`은 보이는 영역을, `aspectFit`은 전체 이미지를 분석합니다.

`KLPaletteAnalyzer`는 `KLAdaptivePalette`를 반환합니다. 결과에는 `KLPaletteCandidate`, `confidence`, 소스 색, 색조, 밝고 어두운 배경과 전경이 포함됩니다. `KLContrastPolicy.foreground(for:)`는 실제 대비로 전경색을 선택합니다.

`KLPaletteAnalysisConfiguration`은 최대 변 길이와 전체 픽셀 수를 제한합니다. `rasterPlan(for:)`은 래스터 크기와 RGBA 메모리 요구량을 보여 줍니다. `KLPerceptualColor.interpolate(from:to:amount:)`는 OKLCH 보간에, `normalizedControlSurface(_:)`는 탁한 색과 과한 채도 억제에 사용합니다.

캐시 키는 `cacheID`, 픽셀, 기하, 표시 모드, 앵커로 결정됩니다. 이미지가 같으면 다시 분석하지 않습니다.

