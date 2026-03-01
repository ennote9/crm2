# Acceptance Criteria v0.1 — Outbound Order (MVP)

## 1) Draft/Release
- Создание Draft с 1+ строкой.
- В Draft строки/qty редактируемы.
- Release фиксирует baseline `planned_qty_initial` и переводит в Released.
- После Release — read-only.

## 2) Allocate
- Allocate только из Released, только Supervisor.
- Создаются reservations, обновляется qty_reserved.
- Результирующий статус: Allocated / Partially_Allocated / Shortage.
- Остатки не уходят в минус.

## 3) Picking
- Start Picking только если есть reserve.
- Создаются pick_tasks.
- Complete Picking только когда нет открытых задач.
- qty_picked корректно отражает факт.

## 4) Packing/HU
- Start Packing только если qty_picked>0.
- Packing требует HU и contents.
- Complete Packing только если весь picked распределён и нет превышений.
- qty_packed считается из HU contents.

## 5) Ship
- Ship только из Packed, не On_Hold, HU>=1, picked==packed (или 0).
- Ship создаёт 1 shipment и ставит qty_shipped=qty_packed.
- При честном shortage требуется подтверждение (W_SHP_001).
- short_forecast (от packed) и short_final (от shipped) корректны.

## 6) Hold
- Hold требует reason+comment.
- Hold блокирует allocate/pick/pack/ship.
- Unhold возвращает в previous_status.

## 7) UI/Permissions
- Кнопки строго по available_actions.
- Причины недоступности через disabled_actions/ошибки E_*.
- Аудит доступен в Events.

## 8) Demo scenarios (для приёмки)
1) Полная отгрузка без shortage.
2) Честный shortage с подтверждением.
3) Hold на любом этапе → блокировка → Unhold → продолжение.
