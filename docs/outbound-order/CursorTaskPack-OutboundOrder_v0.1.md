# Cursor Task Pack — Outbound Order v0.1

## Guardrail (вставлять в начало)
@docs/outbound-order/DecisionLog.md
@docs/outbound-order/StateMachineSpec.md
@docs/outbound-order/MessageCatalog.md

Правила:
- документы — единственный источник истины
- нельзя менять статус напрямую (PATCH/UPDATE status)
- нельзя добавлять новые статусы/ошибки/переходы
- UI доступность действий — только по available_actions/disabled_actions

## Пакеты задач (backend)
B1 DataContract → миграции/DDL  
B2 Seed+Numbering → роли, reason_codes, order_no  
B3 StateMachine enforcement  
B4 API endpoints (command-style)  
B5 Short baseline/forecast/final  
B6 Ship rules (strict MVP)  
B7 Concurrency+Idempotency  
B8 UI Actions Provider  
B9 Permissions (/me, /permissions)  
B10 Automated tests (critical)

Рекомендуемая гранулярность: 1 команда/переход = 1 PR.
