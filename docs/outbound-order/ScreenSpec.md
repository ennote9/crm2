# Screen Spec v0.1 — Outbound Order (MVP)

## Общие правила
- Все действия/кнопки — по `ui.available_actions`.
- Причины недоступности — по `ui.disabled_actions` (tooltip/snack).
- Ошибки показываются по `E_*`, предупреждения — по `W_*`.

## 1) Outbound Orders List
Обязательные колонки:
- order_no, status, warehouse, created_at, requested_ship_at (опц.)
Фильтры:
- status, warehouse, search(order_no/text)
Действия:
- Create (если разрешено), открыть Details.

## 2) Order Details
### Header
- order_no, status, warehouse, created_at/created_by, requested_ship_at (опц.), priority (опц.)
- индикаторы: On Hold, Shortage
- кнопки: Release/Allocate/Start/Complete Picking/Start/Complete Packing/Ship/Close/Hold/Unhold (по available_actions)

### Summary (агрегаты)
- total ordered(baseline), reserved, picked, packed, shipped, short_forecast, short_final

### Tabs
A) Lines:
- sku+name, planned_qty_initial, qty_reserved, qty_picked, qty_packed, qty_shipped, short_forecast, short_final, line_status (опц.)
- Draft: line edit/delete
B) Reservations: line→location/lot→qty_reserved
C) Pick Tasks: list + completion with reason rules
D) Handling Units: HU list + contents; Packing режим: create/add content
E) Events: audit trail

## 3) Pick Task Details (если отдельный)
- qty_to_pick, input qty_picked, reason_code (обязателен при недоборе)
- complete

## 4) Packing workspace (если отдельный)
- HU list + contents + unassigned remaining
- complete packing

## 5) Ship section
- optional fields carrier/dock/tracking
- confirm dialog for W_SHP_001 (partial shortage)
