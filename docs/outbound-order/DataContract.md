# Data Contract — Outbound Order (MVP) v0.1

Целевая БД: PostgreSQL (структура применима и к другим SQL).

## 1) Справочники

### users
- id UUID PK
- email text UNIQUE NULL
- full_name text NOT NULL
- is_active boolean NOT NULL default true
- created_at timestamptz NOT NULL default now()

### roles
- id UUID PK
- code text UNIQUE NOT NULL (Sales/Supervisor/Picker/Packer/Shipping/Admin)
- name text NOT NULL

### user_roles
- user_id UUID FK→users(id)
- role_id UUID FK→roles(id)
- PK (user_id, role_id)

### products
- id UUID PK
- sku text UNIQUE NOT NULL
- name text NOT NULL
- uom text NOT NULL
- gtin text NULL
- is_active boolean NOT NULL default true

### warehouses
- id UUID PK
- code text UNIQUE NOT NULL
- name text NOT NULL
- gln text NULL

### locations
- id UUID PK
- warehouse_id UUID FK→warehouses(id)
- code text NOT NULL
- zone text NULL
- gln text NULL
- UNIQUE (warehouse_id, code)

### reason_codes
- id UUID PK
- category text NOT NULL (HOLD/SHORTAGE/PICK_EXCEPTION/PACK_EXCEPTION/CANCEL)
- code text NOT NULL
- name text NOT NULL
- UNIQUE (category, code)

## 2) Запасы (минимум для резерва)

### inventory_lots (опционально)
- id UUID PK
- product_id UUID FK→products(id)
- lot_code text NOT NULL
- expiry_date date NULL
- UNIQUE (product_id, lot_code)

### inventory_quants
- id UUID PK
- product_id UUID FK→products(id)
- location_id UUID FK→locations(id)
- lot_id UUID FK→inventory_lots(id) NULL
- qty_on_hand numeric(18,3) NOT NULL default 0
- qty_reserved numeric(18,3) NOT NULL default 0
- updated_at timestamptz NOT NULL default now()
- CHECK (qty_reserved <= qty_on_hand)

## 3) Outbound Order

### outbound_orders
- id UUID PK
- order_no text UNIQUE NOT NULL (OUT-YYYY-######)
- status text NOT NULL (см. SeedNumbering.md)
- warehouse_id UUID FK→warehouses(id) NOT NULL
- ship_to_name text NULL
- ship_to_code text NULL
- requested_ship_at timestamptz NULL
- priority int NOT NULL default 0
- notes text NULL
- created_by UUID FK→users(id) NOT NULL
- created_at timestamptz NOT NULL default now()
- updated_at timestamptz NOT NULL default now()
- SCOR timestamps:
  - released_at, allocated_at, pick_started_at, pick_completed_at,
    pack_started_at, pack_completed_at, shipped_at, closed_at,
    hold_created_at, hold_resolved_at, shortage_detected_at (all timestamptz NULL)

Индексы (минимум):
- (status, created_at)
- (warehouse_id, status)
- (order_no)

### outbound_order_lines
- id UUID PK
- order_id UUID FK→outbound_orders(id) NOT NULL
- line_no int NOT NULL
- product_id UUID FK→products(id) NOT NULL

Qty:
- qty_ordered numeric(18,3) NOT NULL
- planned_qty_initial numeric(18,3) NULL (фиксируется при Release)
- qty_reserved numeric(18,3) NOT NULL default 0
- qty_picked numeric(18,3) NOT NULL default 0
- qty_packed numeric(18,3) NOT NULL default 0
- qty_shipped numeric(18,3) NOT NULL default 0
- cancelled_qty numeric(18,3) NOT NULL default 0
- short_forecast numeric(18,3) NOT NULL default 0
- short_final numeric(18,3) NOT NULL default 0

Optional:
- status text NULL
- notes text NULL

Constraints:
- UNIQUE (order_id, line_no)
- CHECK (qty_ordered > 0)
- CHECK (qty_packed <= qty_picked)
- CHECK (qty_shipped <= qty_packed)

## 4) Reservations

### reservations
- id UUID PK
- order_id UUID FK→outbound_orders(id) NOT NULL
- line_id UUID FK→outbound_order_lines(id) NOT NULL
- quant_id UUID FK→inventory_quants(id) NOT NULL
- qty_reserved numeric(18,3) NOT NULL
- created_at timestamptz NOT NULL default now()
- CHECK (qty_reserved > 0)

## 5) Picking

### pick_tasks
- id UUID PK
- order_id UUID FK→outbound_orders(id) NOT NULL
- line_id UUID FK→outbound_order_lines(id) NOT NULL
- from_location_id UUID FK→locations(id) NOT NULL
- lot_id UUID FK→inventory_lots(id) NULL
- qty_to_pick numeric(18,3) NOT NULL
- qty_picked numeric(18,3) NOT NULL default 0
- status text NOT NULL (Created/Assigned/In_Progress/Completed/Exception)
- assigned_to UUID FK→users(id) NULL
- reason_code_id UUID FK→reason_codes(id) NULL
- started_at timestamptz NULL
- completed_at timestamptz NULL
- created_at timestamptz NOT NULL default now()
- CHECK (qty_to_pick > 0)
- CHECK (qty_picked <= qty_to_pick)

## 6) Handling Units (Packing)

### handling_units
- id UUID PK
- order_id UUID FK→outbound_orders(id) NOT NULL
- hu_type text NOT NULL (box/pallet)
- sscc text NULL UNIQUE
- parent_hu_id UUID FK→handling_units(id) NULL
- created_by UUID FK→users(id) NOT NULL
- created_at timestamptz NOT NULL default now()

### handling_unit_contents
- id UUID PK
- hu_id UUID FK→handling_units(id) NOT NULL
- line_id UUID FK→outbound_order_lines(id) NOT NULL
- product_id UUID FK→products(id) NOT NULL
- lot_id UUID FK→inventory_lots(id) NULL
- qty numeric(18,3) NOT NULL
- created_at timestamptz NOT NULL default now()
- CHECK (qty > 0)

## 7) Shipment (MVP: 1:1)

### shipments
- id UUID PK
- order_id UUID FK→outbound_orders(id) NOT NULL UNIQUE
- carrier text NULL
- tracking_no text NULL
- dock text NULL
- shipped_by UUID FK→users(id) NOT NULL
- shipped_at timestamptz NOT NULL
- created_at timestamptz NOT NULL default now()

## 8) Events / Audit

### order_events
- id UUID PK
- order_id UUID FK→outbound_orders(id) NOT NULL
- event_type text NOT NULL
- occurred_at timestamptz NOT NULL default now()
- actor_user_id UUID FK→users(id) NULL
- payload jsonb NOT NULL default '{}'::jsonb

Index: (order_id, occurred_at DESC)
