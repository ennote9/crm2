# API Contract — Outbound Order (MVP) v0.1 (Command-style)

## Общие правила
- Все изменения статуса — только через **команды** (actions).
- Команды возвращают обновлённый `order + lines + ui`.
- Команды принимают `Idempotency-Key` (см. ConcurrencyIdempotency.md).

## Чтение (REST для просмотра)
- GET /api/outbound-orders
- GET /api/outbound-orders/{order_id}
- GET /api/outbound-orders/{order_id}/events
- GET /api/outbound-orders/{order_id}/reservations
- GET /api/outbound-orders/{order_id}/pick-tasks
- GET /api/outbound-orders/{order_id}/handling-units

## Команды процесса

### POST /api/outbound-orders
Создать Draft.

Body:
{
  warehouse_id, ship_to_name?, requested_ship_at?, priority?, notes?,
  lines: [{ product_id, qty_ordered, notes? }]
}

201: order Draft.

Errors: E_REL_002, E_REL_003

### POST /api/outbound-orders/{id}/release
Draft → Released (baseline фиксируется).

Errors: E_REL_001, E_REL_002, E_REL_003

### POST /api/outbound-orders/{id}/allocate
Released → Allocated/Partially_Allocated/Shortage.

Errors: E_ALL_001, E_ALL_002

### POST /api/outbound-orders/{id}/start-picking
Allocated/Partially_Allocated → Picking, создаёт pick_tasks.

Errors: E_PCK_001, E_ORD_010

### POST /api/outbound-orders/{id}/complete-picking
Picking → Picked (если нет активных задач).

Errors: E_PTK_002

### POST /api/pick-tasks/{task_id}/start
Created/Assigned → In_Progress

### POST /api/pick-tasks/{task_id}/complete
Body: { qty_picked, reason_code_id?, comment? }
Rules: если qty_picked < qty_to_pick → reason_code обязателен.
Errors: E_PTK_001, E_PTK_003

### POST /api/outbound-orders/{id}/start-packing
Picked → Packing

Errors: E_PAK_001, E_ORD_010

### POST /api/outbound-orders/{id}/handling-units
Создать HU. Body: { hu_type, parent_hu_id? }

### POST /api/handling-units/{hu_id}/contents
Добавить содержимое HU. Body: { line_id, product_id, qty, lot_id? }

### POST /api/handling-units/{hu_id}/assign-sscc
Опционально. Body: { sscc }

### POST /api/outbound-orders/{id}/complete-packing
Packing → Packed; packed считается из HU contents.
Errors: E_PAK_002, E_PAK_003, E_PAK_004

### POST /api/outbound-orders/{id}/ship
Packed → Shipped (MVP: 1 shipment).
Body: { confirm_partial_shortage: bool, carrier?, dock?, tracking_no? }
Errors: E_SHP_001..E_SHP_005; Warning: W_SHP_001

### POST /api/outbound-orders/{id}/close
Shipped → Closed
Errors: E_CLS_001

### POST /api/outbound-orders/{id}/hold
Body: { reason_code_id, comment }
Errors: E_HLD_001

### POST /api/outbound-orders/{id}/unhold
On_Hold → previous_status

## Формат ошибки (единый)
{
  "error": {
    "code": "E_...",
    "key": "message.key",
    "message": "Текст",
    "details": { ... }
  }
}
