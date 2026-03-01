# Instrumentation Spec v0.1 — Outbound Order (MVP)

## Два потока
- Client UX Events (Flutter): поиск, клики, хоткеи, показ ошибок.
- Server Business Events: команды процесса, ошибки, латентность, конфликты.

## Обязательные поля корреляции
ts, env, app_version, platform, session_id, user_id, role, screen, order_id, request_id, idem_key.

## UX события (минимум)
ux.nav.screen_view
ux.orders.search_submitted
ux.order.next_step_clicked
ux.message.shown (E/W/I)
ux.pick_task.completed
ux.hu.created / ux.hu.content_added
ux.ship.confirm_shortage_shown / accepted
ux.hotkey.used

## Server события (минимум)
srv.command.succeeded / failed / conflict
srv.error.returned (E_*)
srv.warning.returned (W_*)
srv.invariant.violation_detected

## Dashboard v0.1
Top errors E_*
Latency p50/p95 по командам
Time-to-Ship (Released→Shipped)
% Orders with Hold/Shortage
Keyboard usage rate
