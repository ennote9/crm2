# UI Actions Contract v0.1

## Назначение
Backend возвращает набор действий, доступных пользователю **в текущем статусе и с текущими данными**, чтобы UI не дублировал бизнес-логику.

## Структура
`ui.available_actions[]` — разрешённые действия  
`ui.disabled_actions[]` — действия, которые логично рядом, но заблокированы (с причиной)  
`ui.line_actions[]` — действия по строкам  
`ui.ui_hints[]` — подсказки (например, confirm dialog)

Пример:
{
  ui: {
    available_actions: [...],
    disabled_actions: [{action, code, key, message}],
    line_actions: [{line_id, available:[], disabled:[]}],
    ui_hints: [{type, action, code, title, message}]
  }
}

## Enum действий

### Order-level
- ORDER_EDIT_DRAFT
- ORDER_RELEASE
- ORDER_ALLOCATE
- ORDER_START_PICKING
- ORDER_COMPLETE_PICKING
- ORDER_START_PACKING
- ORDER_COMPLETE_PACKING
- ORDER_SHIP
- ORDER_CLOSE
- ORDER_HOLD
- ORDER_UNHOLD

### View actions
- VIEW_RESERVATIONS
- VIEW_PICK_TASKS
- VIEW_HANDLING_UNITS
- VIEW_EVENTS
- VIEW_SHIPMENT

### Line-level
- LINE_EDIT (Draft)
- LINE_DELETE (Draft)
- LINE_VIEW_RESERVATIONS
- LINE_VIEW_HU_CONTENTS
- LINE_REVIEW_EXCEPTIONS

### Packing/HU
- HU_CREATE
- HU_ASSIGN_SSCC
- HU_ADD_CONTENT
- HU_REMOVE_CONTENT (опционально)

## Базовые правила
- Действия выдаются на основе ролей + статуса + условий (HU>=1, нет open tasks, picked==packed, не On_Hold).
- Для partial shortage ship backend выдаёт ui_hints CONFIRM_DIALOG (W_SHP_001) или возвращает warning при попытке ship без флага.

## Мини-контроль (должно быть)
- Released + Supervisor → available: ORDER_ALLOCATE, ORDER_HOLD
- Packed + Shipping + HU>=1 + picked==packed → available: ORDER_SHIP
- Packed + HU=0 → disabled ORDER_SHIP с E_SHP_003
