# Layout Presets (Candidate ArcadeCore Feature)

This document summarizes proven layout patterns across existing TeraPixel games and maps them to reusable presets.

## 1) Square Centered Playfield (GloBlocks)

Use when gameplay must feel identical in portrait and landscape.

- Gameplay area is a centered square fitted into viewport with margins.
- HUD can switch to side column in wider aspect ratios.
- Paddle/grid spacing scales from the same reference size.

Reference implementation:

- `scripts/glo_blocks/layout/PlayLayoutSystem.gd` (`SQUARE_CENTERED`)
- `scripts/glo_blocks/GloBlocksGame.gd`

## 2) Rotate-To-Landscape Playfield (Starfall Redux)

Use when the game flow should stay "forward" while orientation changes (portrait vertical flow, landscape horizontal flow).

- Uses a virtual reference playfield size.
- Rotates gameplay root `+90deg` when landscape.
- Fits scale differently by orientation and recenters transformed playfield.

Reference implementation:

- `scripts/glo_blocks/layout/PlayLayoutSystem.gd` (`ROTATE_TO_LANDSCAPE`)
- `C:/code/TeraPixel/Hydra/TeraPixelStarfallRedux/scripts/Game.gd`

## 3) Safe-Area Anchored UI Shell (LumaRush / ColorCrunch)

Use for modal-heavy and HUD-heavy games with mobile notches and dynamic bars.

- Compute display safe insets.
- Apply inset-aware top/bottom anchors.
- Keep gameplay region independent from UI shell.

Reference implementation:

- `C:/code/TeraPixel/LumaRush/src/core/SafeArea.gd`
- `C:/code/TeraPixel/color_crunch/src/core/SafeArea.gd`

## 4) Adaptive Panel Split (Results / Pause / Shop)

Use for overlays where portrait should stack and landscape should split columns.

- Switch layout at aspect thresholds (`~1.45-1.55`).
- Derive panel dimensions from viewport percentages with clamps.
- Run typography compaction loops to prevent overflow.

Reference implementation:

- `C:/code/TeraPixel/LumaRush/src/scenes/Results.gd`
- `C:/code/TeraPixel/color_crunch/src/scenes/Results.gd`
- `C:/code/TeraPixel/LumaRush/src/scenes/PauseOverlay.gd`

## Recommended ArcadeCore Surface

- `PlayLayoutSystem` (math + transforms, no game logic)
- `SafeArea` (inset service)
- `HudLayoutPolicy` (top-row vs side-column rule)
- `OverlayPanelLayout` (adaptive panel sizing + split mode)

Suggested preset keys:

- `square_centered`
- `rotate_landscape`
- `safe_shell`
- `overlay_split`
