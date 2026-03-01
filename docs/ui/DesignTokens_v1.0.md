# UI Design Tokens v1.0 — Modern Dynamics Dense (Light + Dark)

## 0) Principles
- Tokens are the *single source of truth* for visuals.
- Two themes: Light/Dark.
- Two densities: Dense (default) / Comfortable (optional).
- Accessibility: visible focus, contrast, non-color-only status.

## 1) Typography
### Font family
- UI: Inter (recommended) or Segoe UI (Microsoft-like).

### Sizes (desktop)
- xs: 12 / 16
- sm: 13 / 18
- md: 14 / 20
- lg: 16 / 22
- xl: 20 / 28
- 2xl: 24 / 32

### Weights
- regular 400, medium 500, semibold 600

Usage:
- Page title: xl / semibold
- Section title: lg / semibold
- Table header: xs|sm / medium
- Table cell: sm / regular
- KPI value: 2xl / semibold

## 2) Spacing (8px grid)
Scale: 0,4,8,12,16,20,24,32,40,48  
Dense reduces **vertical** paddings by ~10–20%.

## 3) Radius
xs 4, sm 6, md 8, lg 12  
- Inputs/buttons: sm
- Cards/panels: md
- Chips: lg

## 4) Elevation
- shadow.0 none
- shadow.1 subtle (cards/popovers)
- shadow.2 medium (modals)
Dark theme: prefer borders/overlays over heavy shadows.

## 5) Colors — Light
Neutrals:
- bg #F7F8FA
- surface #FFFFFF
- surface.alt #F2F4F7
- border #E3E7EE
- divider #EDF0F5
- text.primary #111827
- text.secondary #4B5563
- text.muted #6B7280

Accent:
- accent #2563EB (adjustable)
- accent.subtle = very light background for accent

Semantic:
- success #16A34A
- warning #D97706
- danger  #DC2626
- info    #2563EB
- neutral #6B7280

Interaction:
- hover.bg = subtle overlay
- selected.bg = subtle accent overlay
- focus.ring = accent

## 6) Colors — Dark (not inversion)
- bg #0B1220
- surface #0F1A2B
- surface.alt #111F33
- border #22324A
- divider #1B2A40
- text.primary #E5E7EB
- text.secondary #AAB3C2
- text.muted #8892A6
- accent #4F8BFF (dark-optimized)

## 7) Component sizing (desktop)
Buttons:
- height dense 32 / default 36 / large 40

Inputs:
- height dense 32 / default 36

Table:
- header dense 32 / default 36
- row dense 36 / default 44
- cell padding x=12, y dense=6, y default=10

Chips:
- height 22–24, pad x 8–10, radius lg

## 8) Focus (WCAG)
- ring width 2, offset 2, color accent (visible in light/dark)

## 9) Motion
fast 120ms, normal 180ms, slow 240ms (no playful animations)

## 10) Mobile touch targets
- controls 44–48px height, inputs 44px.
