# UI Documentation — Modern Dynamics Dense (v1.0)

**Generated:** 2026-02-28

## What this is
This folder contains the **UI/UX redesign specification** for the Warehouse ERP interface:
- Modern SaaS look
- **Dense, Dynamics-like data grid** workflow
- Light + Dark themes
- Desktop-first, with clear Mobile adaptation rules

These docs are meant to be used by:
- Designers / Product owners (to align direction)
- Flutter/UI developers (to implement)
- Cursor AI (to implement consistently)

## Golden rules
1) UI uses **Design Tokens** (no random colors/sizes).
2) UI does **NOT** guess business rules. Actions availability comes from backend:
   `available_actions / disabled_actions / ui_hints` and `E_* / W_*`.
3) Desktop = tables; Mobile = cards/flows.

## File index (recommended reading order)
1. `DesignTokens_v1.0.md`
2. `AppShell_Spec_v1.0.md`
3. `DataGrid_Spec_v1.0.md`
4. `CommandToolbar_Spec_v1.0.md`
5. `Filters_Spec_v1.0.md`
6. `SavedViews_Spec_v1.0.md`
7. `BulkActionBar_Spec_v1.0.md`
8. `StatusChips_Spec_v1.0.md`
9. `DialogsNotifications_Spec_v1.0.md`
10. `Worklist_Orders_Spec_v1.0.md`
11. `OrdersStats_Spec_v1.0.md`
12. `ObjectPage_Order_Spec_v1.0.md`
13. `TaskPages_PickPack_Spec_v1.0.md`
14. `SettingsPage_Spec_v1.0.md`
15. `MobileAdaptation_Spec_v1.0.md`
16. `UIImplementationRules_Cursor_v1.0.md`
17. `UI_Cursor_Task_Pack_v1.0.md`
18. `PR_Checklist_v1.0.md`
