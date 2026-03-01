# UX Acceptance Criteria v0.1

## Глобально
- Кнопки/действия строго по available_actions/disabled_actions.
- Причины блокировок объясняются (disabled_actions или E_*).
- Keyboard-first: основные сценарии выполняются без мыши.

## Метрики (целевые для MVP)
- Найти и открыть заказ по order_no/SKU: ≤ 10 сек.
- Next Step в карточке: ≤ 2 клика или Ctrl+Enter.
- Закрыть pick task без exception: ≤ 8 сек (клавиатура).
- HU create + add content (1 позиция): ≤ 15 сек.

## Экранные критерии
- Orders List: sticky filters, ясный empty state.
- Order Details: sticky header + Next Step + summary.
- Pick Tasks: reason обязателен при недоборе, быстрые причины.
- Packing: Unassigned remaining видно, complete объясняет блокировку.
- Ship: readiness checklist, confirm shortage.
