# Decision Log — Outbound Order (MVP) v0.1

## 1) Область MVP
**В фокусе:** процесс “Заказ на отгрузку” (Outbound Order) от создания до закрытия.  
**Не делаем в MVP:** частичные shipments / Partially Shipped / несколько отгрузок на один заказ.

## 2) Роли
- Sales
- Supervisor
- Picker
- Packer
- Shipping
- Admin (тех/управление)

## 3) Статусы заказа
Основная цепочка:  
Draft → Released → Allocating → Allocated / Partially_Allocated → Picking → Picked → Packing → Packed → Shipped → Closed

Исключения:  
On_Hold, Shortage, Cancelled

## 4) Статусы строк
Open → Allocated/Partial → Picked/Partial → Packed/Partial → Shipped/Partial → Closed/Cancelled

UI показывает количества: Ordered(baseline)/Reserved/Picked/Packed/Shipped/Short/Cancelled.

## 5) События и timestamps (SCOR-ready)
`released_at`, `allocated_at`, `pick_started_at`, `pick_completed_at`,  
`pack_started_at`, `pack_completed_at`, `shipped_at`, `closed_at`,  
`hold_created_at`, `hold_resolved_at`, `shortage_detected_at`.

Все изменения пишем в `order_events`.

## 6) GS1 (мягкое внедрение)
- GTIN/GLN — опционально
- SSCC — опционально, но модель грузомест (HU) присутствует сразу

## 7) Baseline и Short (ключевое правило)
Baseline по строке фиксируется на Release: `planned_qty_initial`.

Short:
- **Short forecast:** `max(0, planned_qty_initial - cancelled_qty - packed_qty)`  
- **Short final:** `max(0, planned_qty_initial - cancelled_qty - shipped_qty)`  
В MVP без отмен: `cancelled_qty = 0`.

## 8) Ship (строгое правило MVP)
- Ship только из **Packed**
- Заказ не **On_Hold**
- Есть **≥1 HU**
- По строкам: `shipped_qty ≤ packed_qty`
- Ship разрешён только если упаковка завершена:  
  `picked_qty == packed_qty` либо `picked_qty == 0`
- Частичная недовыполненность допускается только как **“честный shortage”**:  
  `planned_qty_initial > packed_qty` при `picked_qty == packed_qty`
- **Не делаем:** частичные shipments / partially shipped.

## 9) Идентификаторы
- Внутренние PK во всех таблицах — **UUID**
- Для пользователей и документов — отдельные человекочитаемые номера, например: `OUT-YYYY-######`

## 10) Источник истины по правилам
- Все правила процесса/переходы/валидации живут на **backend**
- Flutter/UI отображает и вызывает команды, используя `available_actions` и `E_* / W_*`
