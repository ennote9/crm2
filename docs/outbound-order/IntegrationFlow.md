# Integration Flow Spec v0.1 — Flutter ↔ Backend

## Общие правила
- UI использует `ui.available_actions` и `E_* / W_*`.
- Для POST команд отправляется `Idempotency-Key` и `X-Request-Id`.
- После команды UI обновляет карточку (из ответа или через GET).

## Flows

### Create Draft
- POST /api/outbound-orders (+ Idempotency-Key)
- On success: открыть Details.

### Release
- POST /api/outbound-orders/{id}/release (+ Idempotency-Key)
- On success: обновить Details; показать I_REL_001.

### Allocate
- POST /api/outbound-orders/{id}/allocate (+ Idempotency-Key)
- Next:
  - Allocated: I_ALL_002
  - Partially_Allocated: I_ALL_003
  - Shortage: W_ALL_001 dialog

### Start Picking
- POST /api/outbound-orders/{id}/start-picking (+ Idempotency-Key)
- On success: открыть Pick Tasks.

### Pick task complete
- POST /api/pick-tasks/{task_id}/complete (+ Idempotency-Key)
- Если qty_picked < qty_to_pick → reason обязателен (E_PTK_001).

### Complete Picking
- POST /api/outbound-orders/{id}/complete-picking (+ Idempotency-Key)

### Start Packing
- POST /api/outbound-orders/{id}/start-packing (+ Idempotency-Key)

### HU / Contents
- POST /api/outbound-orders/{id}/handling-units
- POST /api/handling-units/{hu_id}/contents
- (opt) POST /api/handling-units/{hu_id}/assign-sscc

### Complete Packing
- POST /api/outbound-orders/{id}/complete-packing

### Ship
- POST /api/outbound-orders/{id}/ship
- Если partial shortage: UI показывает confirm dialog (W_SHP_001) и повторяет ship с `confirm_partial_shortage=true`.

### Close
- POST /api/outbound-orders/{id}/close

### Hold/Unhold
- POST /api/outbound-orders/{id}/hold (reason+comment)
- POST /api/outbound-orders/{id}/unhold

## Retry policy
- POST: retry only with same Idempotency-Key.
- 409: показать E_CONC_001 и refresh GET /outbound-orders/{id}.
