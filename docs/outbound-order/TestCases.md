# Test Cases Spec v0.1 — Outbound Order (MVP)

Формат: Given / When / Then / Expect code.

## Release
- TC-REL-001: Draft + valid → ORDER_RELEASE → Released, baseline set, ORDER_RELEASED, released_at set (I_REL_001)
- TC-REL-002: Draft без строк → ORDER_RELEASE → E_REL_001
- TC-REL-003: Draft qty<=0 → ORDER_RELEASE → E_REL_002
- TC-REL-004: Draft missing required fields → ORDER_RELEASE → E_REL_003

## Allocate
- TC-ALL-001: Released + stock enough → ORDER_ALLOCATE → Allocated + reservations + allocated_at (I_ALL_002)
- TC-ALL-002: Released + partial stock → ORDER_ALLOCATE → Partially_Allocated + allocated_at (I_ALL_003)
- TC-ALL-003: Released + no stock → ORDER_ALLOCATE → Shortage + SHORTAGE_DETECTED + shortage_detected_at (W_ALL_001)
- TC-ALL-004: On_Hold → ORDER_ALLOCATE → E_ALL_001

## Picking
- TC-PCK-001: Allocated + reserved>0 → START_PICKING → Picking + tasks + pick_started_at (I_PCK_001)
- TC-PCK-002: Allocated + reserved=0 → START_PICKING → E_PCK_001
- TC-PCK-003: Picking + open tasks → COMPLETE_PICKING → E_PTK_002
- TC-PCK-004: Picking + all tasks closed → COMPLETE_PICKING → Picked + pick_completed_at (I_PCK_002)

## Pick task
- TC-PTK-001: qty_to_pick=10 → complete(10) → Completed
- TC-PTK-002: qty_to_pick=10 → complete(11) → E_PTK_003
- TC-PTK-003: qty_to_pick=10 → complete(8, reason null) → E_PTK_001
- TC-PTK-004: qty_to_pick=10 → complete(8, reason NOT_FOUND) → Exception/Completed-with-exception

## Packing
- TC-PAK-001: Picked sum(qty_picked)=0 → START_PACKING → E_PAK_001
- TC-PAK-002: Picked qty_picked>0 → START_PACKING → Packing + pack_started_at (I_PAK_001)
- TC-PAK-003: Packing + unassigned picked → COMPLETE_PACKING → E_PAK_002
- TC-PAK-004: Packing + packed>picked → COMPLETE_PACKING → E_PAK_003
- TC-PAK-005: Packing + assigned all + ok qty → COMPLETE_PACKING → Packed + pack_completed_at (I_PAK_002)

## Ship
- TC-SHP-001: status != Packed → SHIP → E_SHP_001
- TC-SHP-002: Packed + On_Hold → SHIP → E_SHP_002
- TC-SHP-003: Packed + HU=0 → SHIP → E_SHP_003
- TC-SHP-004: Packed + picked>packed → SHIP → E_SHP_004
- TC-SHP-005: Packed + honest shortage + no confirm → SHIP → W_SHP_001
- TC-SHP-006: Packed full → SHIP → Shipped + shipped_at + short_final=0 (I_SHP_001)
- TC-SHP-007: Packed honest shortage + confirm → SHIP → Shipped + short_final>0 (I_SHP_001)

## Close
- TC-CLS-001: status != Shipped → CLOSE → E_CLS_001
- TC-CLS-002: Shipped → CLOSE → Closed + closed_at (I_CLS_001)

## Hold/Unhold
- TC-HLD-001: рабочий статус → HOLD(with reason) → On_Hold + hold_created_at
- TC-HLD-002: HOLD without reason → E_HLD_001
- TC-HLD-003: On_Hold → UNHOLD → previous_status + hold_resolved_at

## UI Actions (sanity)
- TC-UIA-001: Released+Supervisor → available has ORDER_ALLOCATE; ORDER_SHIP disabled with E_SHP_001
- TC-UIA-002: Packed+Shipping+HU>=1+picked==packed → available has ORDER_SHIP
- TC-UIA-003: Packed+HU=0 → disabled ORDER_SHIP with E_SHP_003
