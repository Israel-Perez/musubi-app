# HU-62 — Recibir un recordatorio de la entrega y avisar "Ya llegué" (tareas, app)

## T1 — Detallar la spec
- **Estado:** ✅ Hecho (23-Nov-2026).

## T2 — Datos y canal
- **Qué:** `Order` con quién llegó, `OrderRepository.arrived` y el canal `musubi/calendar`.
- **Prueba:** `test/features/orders/order_data_test.dart` y `test/features/orders/delivery_actions_test.dart` (canal).
- **Estado:** ✅ Hecho.

## T3 — Pantallas
- **Qué:** `DeliveryCard` en `Pedido-pago`, `ArrivalBar` en el chat y los íconos de los avisos.
- **Prueba:** `test/features/orders/delivery_actions_test.dart` y `test/integration/orders_flow_test.dart`.
- **Estado:** ✅ Hecho.

## T4 — Prueba en el celular
- **Qué:** con la API `0.5.0-alpha.43` y un pedido confirmado para dentro de una hora: el recordatorio, "Ya llegué" desde el pedido y desde el chat, y "Agregar al calendario".
- **Estado:** ⏳ Por hacer (en el siguiente lote de Google Play).
