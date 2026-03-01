# Screen UX Addendum v0.1 — Outbound Order (MVP)

## Orders List
- Sticky filters + quick search (Enter apply, Esc clear).
- Быстрые представления: All/On Hold/Shortage/Today.
- Enter открывает выделенный заказ.

## Order Details
- Sticky header: order_no + status + Next Step CTA.
- Next Step CTA + причина блокировки рядом.
- Summary строка агрегатов (Ordered/Reserved/Picked/Packed/Shipped + Short forecast/final).
- Панель “что мешает” (shortage/hold/exceptions) со ссылками на вкладки.

## Lines
- Подсветка проблемных строк (short/exceptions).
- Быстрые действия: view reservations / view HU contents.

## Pick Tasks
- Поток: после complete — следующий task.
- reason появляется только когда нужен (qty_picked < qty_to_pick).
- Быстрые причины: NOT_FOUND/DAMAGED/COUNT_MISMATCH.

## Packing (HU)
- Unassigned remaining всегда виден.
- Complete Packing показывает причину блокировки (E_PAK_002) и ведёт к проблеме.

## Ship
- Чек-лист готовности (HU>=1, not hold, picked==packed).
- Partial shortage: confirm dialog W_SHP_001.

## Events
- Фильтры Process/Exceptions, раскрытие payload.
