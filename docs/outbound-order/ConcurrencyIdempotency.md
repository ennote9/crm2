# Concurrency & Idempotency Spec v0.1 — Outbound Order (MVP)

## 1) Атомарность
Каждая команда процесса выполняется в одной транзакции.

## 2) Команды, требующие строгой транзакционности
- ORDER_ALLOCATE
- pick_task.complete
- ORDER_COMPLETE_PACKING
- ORDER_SHIP
(и также release/close/hold/unhold — как state transitions)

## 3) Что блокируем
- Order-level lock: строка outbound_orders по order_id для всех команд, меняющих статус/состояние.
- Inventory-level lock: inventory_quants, участвующие в allocate.
- Task-level lock: pick_tasks по task_id при complete.

## 4) Idempotency-Key
- Заголовок: Idempotency-Key: <uuid>
- Хранение: таблица idempotency_keys (key, user_id, command, target_id, request_hash, response_snapshot, created_at)
- Повтор запроса с тем же ключом возвращает сохранённый ответ.

## 5) Защита от двойного Allocate
MVP правило: allocate разрешён только из Released.
Повтор allocate возможен только через отдельный reallocate (вне MVP).

## 6) Защита от двойного Ship
- UNIQUE(order_id) в shipments
- Ship:
  - проверяет status=Packed
  - пытается создать shipment
  - при нарушении UNIQUE: вернуть E_SHP_005 или отдельный E_SHP_ALREADY_SHIPPED (если добавите)

## 7) Конфликты
- 409 Conflict + E_CONC_001, UI делает refresh.
