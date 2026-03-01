# Non-Functional Requirements (NFR) v0.1 — Outbound Order (MVP)

## 1) Performance
- GET order details: p50 ≤ 300ms, p95 ≤ 800ms
- Commands: p50 ≤ 800ms, p95 ≤ 2000ms (Allocate допускает до p95 4000ms в MVP)
- Все списки — только с пагинацией.

## 2) Reliability/Consistency
- Каждая команда = транзакция, на ошибке rollback.
- Инварианты: packed<=picked, shipped<=packed, reserved<=on_hand.
- Запрещены ручные изменения статуса (только actions).

## 3) Idempotency
- Все команды процесса принимают Idempotency-Key.
- Повтор с тем же ключом возвращает тот же результат.
- TTL ключей: 24–72ч (MVP: 24ч).

## 4) Concurrency
- Order-level lock для команд.
- Inventory-level lock для allocate.
- Task-level lock для pick_task.complete.
- При конфликте: 409 + E_CONC_001.

## 5) Logging/Audit
- Техлоги содержат: X-Request-Id, Idempotency-Key, user_id, target_id, command, result, duration.
- Бизнес-аудит: order_events.

## 6) Error contract
- Единый формат ошибки (code/key/message/details).
- Классы: 400/403/404/409/500.

## 7) Security
- Авторизация на все команды.
- Проверка прав по ролям.
- Ограничение доступа к данным (при необходимости по складам/периметру).

## 8) Observability
- Метрики: count commands, latency p50/p95, errors by code, conflicts 409.
- Корреляция по X-Request-Id.

## 9) Versioning
- Предпочтительно /api/v1/...
- Enum actions и keys — не менять строками (только добавлять).
