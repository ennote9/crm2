# State Machine Spec — Outbound Order (MVP) v0.1

Свод правил: статус → команда → условия → next → события → ошибки.

## Draft → Released
Cmd: ORDER_RELEASE (Sales, Supervisor)  
Pre: есть строки; qty>0; обязательные поля заполнены  
Effects: status=Released; planned_qty_initial=qty_ordered  
Events: ORDER_RELEASED; released_at  
Errors: E_REL_001/002/003

## Released → Allocation result
Cmd: ORDER_ALLOCATE (Supervisor)  
Pre: status=Released; не On_Hold; есть строки  
Effects: status=Allocating; reservations; qty_reserved  
Events: ALLOCATION_STARTED; ALLOCATION_COMPLETED_*; allocated_at; при shortage: SHORTAGE_DETECTED + shortage_detected_at  
Next: Allocated / Partially_Allocated / Shortage  
Errors: E_ALL_001/002

## Allocated/Partially_Allocated → Picking
Cmd: ORDER_START_PICKING (Supervisor)  
Pre: sum(qty_reserved)>0; не On_Hold  
Effects: create pick_tasks; status=Picking  
Events: PICKING_STARTED; pick_started_at  
Errors: E_PCK_001, E_ORD_010

## Picking → Picked
Cmd: ORDER_COMPLETE_PICKING (Supervisor/System)  
Pre: все pick_tasks закрыты  
Effects: агрегировать qty_picked; status=Picked  
Events: PICKING_COMPLETED; pick_completed_at  
Errors: E_PTK_002

## Picked → Packing
Cmd: ORDER_START_PACKING (Packer, Supervisor)  
Pre: sum(qty_picked)>0; не On_Hold  
Effects: status=Packing  
Events: PACKING_STARTED; pack_started_at  
Errors: E_PAK_001, E_ORD_010

## Packing → Packed
Cmd: ORDER_COMPLETE_PACKING (Packer, Supervisor)  
Pre: picked распределён по HU; qty корректны; (опц.) SSCC  
Effects: qty_packed из HU; status=Packed  
Events: PACKING_COMPLETED; pack_completed_at  
Errors: E_PAK_002/003/004

## Packed → Shipped
Cmd: ORDER_SHIP (Shipping, Supervisor)  
Pre: Packed; не On_Hold; HU>=1; picked==packed (или picked==0); при planned>packed требуется подтверждение  
Effects: shipment 1:1; qty_shipped=qty_packed; пересчитать short; status=Shipped  
Events: ORDER_SHIPPED; shipped_at  
Errors: E_SHP_001..005; Warning: W_SHP_001

## Shipped → Closed
Cmd: ORDER_CLOSE (Supervisor/System)  
Pre: Shipped  
Effects: Closed  
Events: ORDER_CLOSED; closed_at  
Errors: E_CLS_001

## Hold/Unhold
ORDER_HOLD: рабочий статус → On_Hold (reason+comment обяз.) → HOLD_APPLIED + hold_created_at (E_HLD_001 если нет причины)  
ORDER_UNHOLD: On_Hold → previous_status → HOLD_RELEASED + hold_resolved_at
