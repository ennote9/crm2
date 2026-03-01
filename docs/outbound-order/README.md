# Outbound Order (MVP) — Documentation Index

**Version:** v0.2  
**Generated:** 2026-02-28

## Назначение
Этот пакет — единая спецификация процесса **Outbound Order (Заказ на отгрузку)** уровня ERP + UX/UI-надстройка для удобной операционной работы.

## Главные принципы
- **Бизнес-правила и статусы — истина на backend.**
- Flutter/UI **не решает**, «можно ли» выполнить действие. UI отображает и вызывает команды по:
  - `ui.available_actions / ui.disabled_actions / ui.ui_hints`
  - коды `E_* / W_*` из Message Catalog
- Любые изменения правил процесса проходят через:
  `Decision Log → State Machine → API/UI Contracts → Tests`
- UX/UI улучшения не должны противоречить правилам процесса.

---

## Состав пакета

### 1) Процесс и контракты (ядро)
1. `DecisionLog.md`
2. `StateMachineSpec.md`
3. `DataContract.md`
4. `ApiContract.md`
5. `MessageCatalog.md`
6. `ReasonCodes.md`
7. `UiActionsContract.md`
8. `PermissionsContract.md`
9. `ConcurrencyIdempotency.md`
10. `SeedNumbering.md`
11. `IntegrationFlow.md`
12. `ScreenSpec.md`
13. `TestCases.md`
14. `AcceptanceCriteria.md`
15. `NFR.md`

### 2) UX/UI документация (надстройка)
16. `UX_Principles_v0.1.md`
17. `Table_Interaction_Spec_v0.1.md`
18. `Screen_UX_Addendum_v0.1.md`
19. `Hotkeys_Focus_Spec_v0.1.md`
20. `UX_AcceptanceCriteria_v0.1.md`
21. `UX_TestCases_v0.1.md`
22. `InstrumentationSpec_v0.1.md`
23. `UX_Backlog_v0.1.md`

### 3) Пакеты задач для Cursor и план реализации
24. `CursorTaskPack-OutboundOrder_v0.1.md`
25. `CursorTaskPack-UX_v0.1.md`
26. `Roadmap_v0.1.md`
27. `SprintPack_v0.1.md`

---

## Быстрый старт по ролям

### Backend developer
`DecisionLog → StateMachineSpec → DataContract → ApiContract`  
Далее: `ConcurrencyIdempotency`, `SeedNumbering`, `MessageCatalog`, `TestCases`.

### Flutter/UI developer
`ScreenSpec → IntegrationFlow → UiActionsContract → MessageCatalog`  
Далее: UX docs (Hotkeys/Table/Screen UX Addendum) и `CursorTaskPack-UX`.

### QA / Analyst
`AcceptanceCriteria → TestCases → StateMachineSpec → MessageCatalog`  
Для UX: `UX_AcceptanceCriteria → UX_TestCases`.

---

## Scope MVP (напоминание)
- **Partial shipments / Partially Shipped / несколько Shipment на заказ — НЕ делаем.**
- Ship только из **Packed**, только при наличии HU, заказ не On Hold.
- `short_forecast` считается от **packed**, `short_final` — от **shipped**.
- PK в БД: **UUID**, человекочитаемые номера: `OUT-YYYY-######`.


## UI Redesign (Modern Dynamics Dense)
See `docs/ui/README.md` for design tokens, component specs, screen specs, mobile adaptation, and Cursor task pack.
