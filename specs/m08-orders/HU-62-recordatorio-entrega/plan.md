# plan.md — HU-62 Recibir un recordatorio de la entrega y avisar "Ya llegué" (app)

## 1. Componentes
- `lib/core/platform/device_calendar.dart` y `MainActivity.kt` (canal `musubi/calendar`).
- `lib/features/orders/presentation/delivery_actions.dart` (`DeliveryCard`, `ArrivalBar` y sus acciones).
- `order_payment_screen.dart` (la tarjeta en un pedido confirmado) y `chat_screen.dart` (la franja).
- `Order`, `OrderRepository.arrived`, `HttpOrderRepository` y `ApiPaths.orderArrived`.
- `notifications_screen.dart`: íconos de `delivery_reminder` y `order_arrived`.

## 2. Decisiones (con su porqué)
- **Intent en lugar de un paquete de calendario:** `ACTION_INSERT` no pide permiso y no agrega dependencias. La persona guarda el evento en su app (00-01: sin paquete nuevo).
- **"Ya llegué" desde 2 horas antes:** es la misma regla que la API (`Order.arrivalLead`), así el botón no sale cuando la API lo rechazaría.
- **Un archivo para la tarjeta y la franja:** comparten `sayArrived` y el texto de la hora (`deliveryWhen`, con `clockTime` del chat).

## 3. Excepciones al stack
Ninguna.

## 4. Guardarraíles
- Sin permisos nuevos (`test/security/android_config_test.dart`).
- El evento del calendario solo lleva el producto, el punto, el número de pedido y el nombre corto de la otra parte.

## 5. Validación
`flutter analyze`, `flutter test`, `scripts/run_integration_tests.ps1` y prueba en el celular (T4).

## 6. Secuencia
T1 → T2 → T3 → T4.
