# UI Implementation Rules for Cursor v1.0

Mandatory context:
- Outbound process docs (DecisionLog/StateMachine/MessageCatalog/UiActionsContract)
- UI system docs (tokens + component specs + screen specs)

Hard bans:
- Don’t change business rules
- Don’t guess action availability (available/disabled/ui_hints only)
- Don’t introduce random styling (tokens only)
- Avoid fixed-width hacks and forced scrollbars

Granularity: 1 task = 1 PR
Acceptance: width, keyboard focus, themes, errors per spec
