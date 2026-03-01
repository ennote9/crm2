# Reason Codes v0.1 (MVP)

## Категории
- HOLD
- SHORTAGE
- PICK_EXCEPTION
- PACK_EXCEPTION
- CANCEL (на будущее)

## HOLD
- QUALITY_CHECK — Проверка качества / разбор
- DOCUMENTS — Нет/ошибка документов
- INCIDENT — Инцидент/разбирательство
- CUSTOMER_REQUEST — Пауза по запросу продаж/клиента
- ADDRESS_ISSUE — Проблема с данными отгрузки

**Минимум MVP:** QUALITY_CHECK, DOCUMENTS, INCIDENT

## SHORTAGE
- NO_STOCK — Нет свободного остатка
- QUARANTINE — Карантин/блок

**Минимум MVP:** NO_STOCK, QUARANTINE

## PICK_EXCEPTION
- NOT_FOUND — Не найдено
- DAMAGED — Брак/повреждение
- COUNT_MISMATCH — Расхождение учёта

**Минимум MVP:** NOT_FOUND, DAMAGED, COUNT_MISMATCH

## PACK_EXCEPTION
- MISSING_ITEM — Не хватает позиции для упаковки

**Минимум MVP:** MISSING_ITEM

## CANCEL (опционально)
- CUSTOMER_CANCEL — Отмена клиентом

## Правила обязательности
1) Hold всегда требует reason_code категории HOLD + comment.
2) Если `qty_picked < qty_to_pick` → обязателен reason_code категории PICK_EXCEPTION.
3) При shortage на allocation фиксируется reason_code категории SHORTAGE (как минимум на уровне заказа/события).
