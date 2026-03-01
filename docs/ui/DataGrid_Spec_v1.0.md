# Data Grid Component Spec v1.0 — Modern Dynamics Dense (Desktop-first)

## Purpose
Enterprise-grade grid: dense rows, selection, bulk actions, sticky header, keyboard support.

## Structure
- GridHeader (sticky)
- GridBody (rows, ideally virtualized)
- GridFooter (pagination)
- BulkActionBar (overlay when selection>0)

## Density
Dense: header ~32, row ~36, padding x12/y6
Comfortable: header ~36, row ~44, padding x12/y10

## Columns
- Types: text, text+secondary, chip, number, date, icon, actions, selection
- Widths: min/preferred/max; grid fills container width.
- Resize (desktop): drag header edges; optional auto-fit.

## Sorting
- Click header toggles asc/desc
- Always show sort indicator
- Must reflect backend query

## Selection
- none/single/multi
- Multi: row checkboxes + header checkbox (indeterminate)
- Selected vs Focused must be visually distinct

## Row actions
- Actions column (⋯) with context actions (permissions-driven)

## Bulk bar
- Appears when selected_count>0
- Sticky bottom, does not break pagination

## States
- Loading: skeleton rows
- Empty: “No items” + clear filters
- Error: message + Retry

## Keyboard (minimum)
- Tab enters grid; ↑/↓ moves focus
- Enter opens row (if configured)
- Space toggles checkbox in multi-select
- Esc clears selection (optional)

## Dark mode
Hover/selection/focus clearly visible, no “muddy” shadows.

## Mobile adaptation
Grid becomes Card List (no horizontal tables).
