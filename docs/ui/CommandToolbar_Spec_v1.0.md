# Command Toolbar Spec v1.0 — Modern Dynamics Dense

## Purpose
Control Worklist: search, filters, sort, views, more, show statistics.

## Desktop layout (left→right)
Search | Filters | Active chips | Sort | Views | More (⋯) | Show statistics toggle
Primary actions (Create/Export/Customize) live in Page Header (right).

## Search
- Ctrl/Cmd+F focus
- Enter apply
- Esc clears
- Optional debounce (prefer Enter-apply for ERP)

## Filters
- Explicit Apply panel (popover)
- Active filter chips row
- +N overflow into popover
- Clear all when active

## Sort
- Shows current sort, applies to backend query

## Views
- System views + custom state indicator

## More
- Reset layout, density switch, manage columns, refresh

## Show statistics (desktop)
- Toggle only changes stats visibility
- Does not reset filters/sort/columns
- Stats loads lazily; table remains interactive

## Mobile
- Replace toggle with Stats button → opens Stats screen
- Filters in bottom sheet
