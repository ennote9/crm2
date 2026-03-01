# Permissions Contract v0.1

## GET /api/me
Возвращает пользователя, роли и базовые permissions для построения меню/разделов.

Пример:
{
  user: { id, full_name, email, is_active },
  roles: ["Supervisor", "Shipping"],
  permissions: {
    modules: { wms:true, sales:false, hr:false, finance:false, analytics:false, admin:true },
    actions: ["ORDER_ALLOCATE","ORDER_SHIP", ...]
  }
}

## GET /api/permissions
Декларативная матрица “роль → modules/actions”, версия.

Пример:
{
  version: "1.0",
  roles: [
    { role:"Sales", modules:["sales","wms"], actions:["ORDER_RELEASE","VIEW_EVENTS","VIEW_RESERVATIONS"] },
    { role:"Supervisor", modules:["wms","admin"], actions:["ORDER_RELEASE","ORDER_ALLOCATE","ORDER_SHIP","ORDER_CLOSE","ORDER_HOLD","ORDER_UNHOLD", ...] },
    { role:"Picker", modules:["wms"], actions:["VIEW_PICK_TASKS"] },
    { role:"Packer", modules:["wms"], actions:["ORDER_START_PACKING","ORDER_COMPLETE_PACKING","HU_CREATE","HU_ADD_CONTENT"] },
    { role:"Shipping", modules:["wms"], actions:["ORDER_SHIP","VIEW_HANDLING_UNITS","VIEW_SHIPMENT"] },
    { role:"Admin", modules:["admin","wms","sales","hr","finance","analytics"], actions:["*"] }
  ]
}

## Правила
- UI может скрывать разделы по `/me`, но окончательная проверка — на backend.
- Отсутствие права на команду → 403 + E_AUTH_001.
