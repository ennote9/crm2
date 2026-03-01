# Seed + Numbering Spec v0.1 (MVP)

## 1) Seeds

### 1.1 Роли (roles)
- Sales
- Supervisor
- Picker
- Packer
- Shipping
- Admin

### 1.2 Reason codes
См. ReasonCodes.md — загрузить все значения v0.1.

### 1.3 Допустимые статусы (валидация)
Order status:
- Draft
- Released
- Allocating
- Allocated
- Partially_Allocated
- Shortage
- Picking
- Picked
- Packing
- Packed
- Shipped
- Closed
- On_Hold
- Cancelled

Pick task status:
- Created
- Assigned
- In_Progress
- Completed
- Exception

HU type (минимум):
- box
- pallet

## 2) Numbering (order_no)

### 2.1 Формат
OUT-YYYY-###### (пример OUT-2026-000123)

### 2.2 Таблица счётчиков
document_counters:
- id UUID PK
- doc_type text NOT NULL (например OUT)
- year int NOT NULL
- last_value int NOT NULL default 0
- UNIQUE (doc_type, year)

### 2.3 Алгоритм (конкурентно безопасно)
В транзакции:
1) SELECT counter FOR UPDATE по (doc_type='OUT', year=YYYY)
2) last_value := last_value + 1
3) order_no := OUT-YYYY-{last_value padded 6}
4) сохранить order_no в outbound_orders

### 2.4 Момент присвоения
Рекомендация: присваивать при создании Draft (допускаются «дырки» при удалении черновиков).
