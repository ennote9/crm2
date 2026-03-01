# Saved Views Spec v1.0 — Modern Dynamics Dense

## View definition
A view stores:
- Filters (including search)
- Sort
- Columns layout (visible/order/width)
- Optional: page size
NOT included: show statistics toggle, selection, scroll position.

## Types
- System views (fixed): All, On Hold, Shortage, Today(24h)
- User views (create/edit/delete)
- Custom state indicator when user modifies a view

## UX
- Selector in toolbar: View: All
- Any manual change → state becomes “Custom”
- Provide “Reset to view defaults”

## Create view dialog
- Name (required)
- Private/shared (optional; MVP private)
- Set as default (optional)

## Mobile
- Views in bottom sheet

## Acceptance
- Selecting a view updates chips/sort/columns
- Custom state shown when modified
