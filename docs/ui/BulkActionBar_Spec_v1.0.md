# Bulk Action Bar Spec v1.0 — Modern Dynamics Dense

## Trigger
Show when selected_count>0.

## Placement (desktop)
Sticky bottom overlay above pagination.

## Content
- Left: Selected: N
- Middle: primary bulk actions (e.g., Hold/Unhold)
- Right: Clear selection
- Secondary actions under More

## Mass Hold
- Opens dialog: reason_code + comment required
- Apply to selected

## Feedback
- Toast success (and partial success if needed)
- Refresh list, clear selection after success (recommended)

## Keyboard
- Tab reachable
- Esc clears selection (if appropriate)

## Mobile
- Long press starts selection mode
- Bottom bar with actions (larger touch)
