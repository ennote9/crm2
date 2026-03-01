# App Shell Spec v1.0 — Modern Dynamics Dense (Desktop + Mobile)

## Goal
Provide consistent navigation + stable layout for enterprise workflows.

## Desktop layout
- Left Sidebar (expanded/collapsed)
- Top Bar (theme toggle, user menu placeholder)
- Content Area (only this scrolls)

### Sidebar
- Expanded: icon + label
- Collapsed: icons only + tooltip
- Active item: accent indicator + higher contrast
- Role-based visibility: show modules per /me permissions

Menu groups (target):
Operations: Orders, Picking, Packing, Shipping
Inventory: Stock, Locations, Movements (later)
Master Data: Products, Users & Roles, Reason Codes
Analytics: Dashboard, KPIs
Admin: Permissions, Settings

### Content scrolling
- Sidebar/TopBar never scroll
- Sticky elements belong inside content (headers, filters)

## Mobile layout
- Burger menu opens Drawer (instead of sidebar)
- Each module is a screen stack
- Back behaves as Android standard

## Theme/density
- Theme toggle in top bar/user menu
- Density switch in settings or "More"

## Acceptance
- Content scroll only in content area
- Drawer works on mobile
- Theme switch doesn’t reset page state
