# Dialogs & Notifications Spec v1.0 — Modern Dynamics Dense

## Channels
1) Inline validation (field-level)
2) Toast/snackbar (success + general errors)
3) Banner/callout (persistent states: On Hold, Unassigned)
4) Modal dialog (confirm W_*)

## Rules
- W_* → modal confirm (e.g., W_SHP_001)
- Input errors → inline + focus on field
- Disabled actions show tooltip (desktop) / toast on tap (mobile)

## Keyboard
- Modal: focus trap; Esc cancels; Enter confirms per global rule
- Toast does not steal focus

## Dark theme
Use subtle backgrounds + colored border/icon.
