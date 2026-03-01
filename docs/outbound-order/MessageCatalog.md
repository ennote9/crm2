# Message Catalog v0.1 (Outbound Order MVP)

## Формат
- code: E_*/W_*/I_* (error/warning/info)
- key: стабильный ключ
- channel: SNACK / DIALOG / INLINE / TOOLTIP
- text_ru: текст сообщения

> Примечание: UI может локализовать по key, backend возвращает code+key+message.

---

## Info (I_*)
- I_REL_001 | order.release.success | SNACK | Заказ выпущен (Released).
- I_ALL_002 | order.allocate.success_full | SNACK | Резервирование выполнено (полностью).
- I_ALL_003 | order.allocate.success_partial | SNACK | Резервирование выполнено (частично).
- I_PCK_001 | order.picking.started | SNACK | Отбор начат.
- I_PCK_002 | order.picking.completed | SNACK | Отбор завершён.
- I_PAK_001 | order.packing.started | SNACK | Упаковка начата.
- I_PAK_002 | order.packing.completed | SNACK | Упаковка завершена.
- I_SHP_001 | order.ship.success | SNACK | Отгрузка выполнена.
- I_CLS_001 | order.close.success | SNACK | Заказ закрыт.

## Warnings (W_*)
- W_ALL_001 | order.allocate.shortage_detected | DIALOG | Обнаружена нехватка товара (Shortage).
- W_SHP_001 | order.ship.confirm_partial_shortage | DIALOG | Отгружается меньше запланированного. Недостача будет зафиксирована как Short.

## Errors (E_*)
### Auth
- E_AUTH_001 | auth.forbidden | SNACK | Недостаточно прав для выполнения действия.

### Release
- E_REL_001 | order.release.no_lines | INLINE | Нельзя выпустить заказ без строк.
- E_REL_002 | order.release.invalid_qty | INLINE | Некорректное количество в строке заказа.
- E_REL_003 | order.release.missing_required_fields | INLINE | Заполните обязательные поля перед выпуском.

### Allocate
- E_ALL_001 | order.allocate.blocked.on_hold | SNACK | Действие недоступно: заказ на Hold.
- E_ALL_002 | order.allocate.no_lines | SNACK | Нельзя резервировать: в заказе нет строк.

### Picking
- E_PCK_001 | order.picking.no_reserved_qty | SNACK | Нельзя начать отбор: нет зарезервированных количеств.
- E_PTK_001 | pick_task.reason_required | INLINE | Укажите причину, если подобрано меньше задания.
- E_PTK_002 | order.picking.has_open_tasks | SNACK | Нельзя завершить отбор: есть незавершённые задания.
- E_PTK_003 | pick_task.qty_exceeds | INLINE | Подобранное количество превышает задание.

### Packing
- E_PAK_001 | order.packing.nothing_to_pack | SNACK | Нельзя начать упаковку: нет подобранных позиций.
- E_PAK_002 | order.packing.unassigned_picked_exists | SNACK | Нельзя завершить упаковку: есть нераспределённые подобранные позиции.
- E_PAK_003 | order.packing.packed_exceeds_picked | SNACK | Ошибка упаковки: упаковано больше, чем отобрано.
- E_PAK_004 | order.packing.sscc_required | SNACK | Для завершения упаковки требуется SSCC у всех грузомест.

### Ship
- E_SHP_001 | order.ship.blocked.not_packed | SNACK | Отгрузка доступна только после упаковки (Packed).
- E_SHP_002 | order.ship.blocked.on_hold | SNACK | Нельзя отгрузить: заказ на Hold.
- E_SHP_003 | order.ship.blocked.no_hu | SNACK | Нельзя отгрузить: нет грузомест (HU).
- E_SHP_004 | order.ship.blocked.unpacked_picked_exists | SNACK | Нельзя отгрузить: есть отобранные позиции, которые не упакованы.
- E_SHP_005 | order.ship.invalid_qty_relation | SNACK | Нельзя отгрузить: нарушено соотношение количеств (shipped/packed).

### Close
- E_CLS_001 | order.close.blocked.not_shipped | SNACK | Нельзя закрыть заказ: сначала выполните отгрузку (Shipped).

### Hold
- E_HLD_001 | order.hold.reason_required | INLINE | Для Hold требуется причина и комментарий.

### Generic
- E_ORD_010 | order.blocked.on_hold | SNACK | Действие недоступно: заказ на Hold.
- E_CONC_001 | concurrency.conflict | SNACK | Состояние изменилось. Обновите экран и повторите.
