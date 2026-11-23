# HU-62 — Recibir un recordatorio de la entrega y avisar "Ya llegué" (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-62 / SCRUM-102 / Sprint 5 (14 nov – 1 dic 2026) / M-08 / [musubi-api:HU-62](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m08-orders/HU-62-recordatorio-entrega)

## Contexto
Jira (SCRUM-102): Como **comprador o vendedor**, quiero **un recordatorio antes de la entrega y poder avisar que ya llegué**, para **no olvidar la cita y encontrarnos rápido en el campus**.

- Pantallas: `Pedido-pago` ("Tu pedido" / "Tu venta") y `Chat-Valeria`. La maqueta no lo tiene: se agrega sin quitar nada (lineamiento 4), con las piezas de 02-04.
- El recordatorio de una hora antes lo manda la API (push `delivery_reminder`). La app lo muestra en "Pedidos" y al tocarlo abre el pedido.
- **Decisiones (23-Nov-2026, para que la usuaria las revise):** "Ya llegué" sale desde 2 horas antes de la entrega, como lo acepta la API. "Agregar al calendario" sale siempre en un pedido confirmado.

**Depende de:** `HU-24` (pedido confirmado), `HU-31` (avisos), `HU-44` (punto de entrega), `02-04` (piezas de la maqueta).

## Requisitos
1. **R1 · Tarjeta "Entrega" en `Pedido-pago`:** solo en un pedido confirmado, debajo del producto.
   - Dice cuándo ("Hoy a la 1:00 p. m.") y dónde ("En Biblioteca con Valeria").
   - Tiene "Agregar al calendario" y, desde 2 horas antes, "Ya llegué".
   - Cuando alguien ya avisó, muestra "Ya le avisaste a Valeria que llegaste." o "Ana ya llegó a Biblioteca.".
2. **R2 · "Agregar al calendario":**
   - Abre la app de calendario con el evento lleno: 30 minutos, en el punto y con el número de pedido. Lo hace con `Intent.ACTION_INSERT` de `CalendarContract`, sin permiso de calendario.
   - Sin app de calendario, lo avisa.
3. **R3 · "Ya llegué":** llama a `POST /orders/{id}/arrived`, avisa "Le avisamos a Valeria que ya llegaste." y deja de mostrarse. Si la API lo rechaza, muestra su mensaje y el botón sigue.
4. **R4 · Chat:** con un pedido confirmado y desde 2 horas antes, una franja arriba de la caja de texto dice "Hoy a la 1:00 p. m. en Biblioteca" y tiene "Ya llegué". Después de avisar, dice "Ya avisaste que llegaste a Biblioteca.".
5. **R5 · Avisos:** `delivery_reminder` (calendario) y `order_arrived` (punto) tienen su ícono en `Notificaciones` y abren el pedido.

## Diseño
- `lib/core/platform/device_calendar.dart`: `DeviceCalendar` y el canal `musubi/calendar` (`MainActivity.kt`, `addEvent`).
- `lib/features/orders/presentation/delivery_actions.dart`:
  - `DeliveryCard` y `ArrivalBar`;
  - `deliveryWhen`, `deliveryEvent`, `addDeliveryToCalendar` y `sayArrived`.
- `Order.buyerArrived`/`sellerArrived`, `iArrived`, `otherArrived` y `canSayArrived`.
- `OrderRepository.arrived` y `ApiPaths.orderArrived`.

## Contratos
Fila `POST /api/v1/orders/{id}/arrived` y `OrderResponse.handover` (`buyerArrivedAt`, `sellerArrivedAt`) de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md); error `orders.arrival_too_early`.

## Tests
- `test/features/orders/delivery_actions_test.dart`:
  - `deliveryWhen`, el evento y `canSayArrived`;
  - el canal del calendario;
  - la tarjeta: avisar, sin "Ya llegué" antes de tiempo, el calendario, sin app de calendario, lo que ve quien vende, el error de la API y un pedido pendiente;
  - la franja del chat.
- `test/features/orders/order_data_test.dart`: `POST` sin cuerpo y la lectura de `handover`.
- `test/integration/orders_flow_test.dart`: contra la API real, "Ya llegué" antes de tiempo da `orders.arrival_too_early`.

## Criterios
- [x] "Agregar al calendario" crea el evento con un intent, sin permiso → `deliveryEvent`, `PlatformDeviceCalendar`, `tres horas antes no hay Ya llegué, pero sí el calendario`, `android_config_test` (sin permisos nuevos).
- [x] "Ya llegué" en el pedido y en el chat avisa a la otra parte → `una hora antes, Ya llegué avisa y queda el estado`, `desde 2 horas antes sale la franja y avisa`, `orders_flow_test`.
- [x] Antes de tiempo no se muestra y la API lo rechaza → `canSayArrived`, `tres horas antes no sale`, `Ya llegué: antes de 2 horas la API lo rechaza`.
- [x] El recordatorio de una hora antes llega como push y abre el pedido → API (`delivery_reminder`, destino `order`) e ícono en `Notificaciones`.
- [ ] Prueba en el celular (T4).

## Límites
- "Ya llegué" no comparte la ubicación.
- iOS no está en alcance: el canal responde `false` y la app avisa que no hay calendario.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 23-Nov-2026 (detallada e implementada)
