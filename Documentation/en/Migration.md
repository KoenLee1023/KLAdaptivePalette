# Migration

Replace host-owned image palette algorithms with a thin adapter that builds `KLPaletteRequest` and maps `KLColor` to the host color type. Keep host models, UI copy, and image hydration outside this package.
