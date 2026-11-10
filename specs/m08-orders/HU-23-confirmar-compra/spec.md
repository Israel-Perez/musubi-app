# HU-23 — Confirmar la compra de un producto (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-23 / SCRUM-42 / Sprint 4 (9 – 20 nov 2026) / M-08 / [musubi-api:HU-23](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m08-orders/HU-23-confirmar-compra)

## Contexto
Jira (SCRUM-42): Como **comprador**, quiero **confirmar la compra de un producto**, para **formalizar el trato con el vendedor**.

- Maqueta: `Chat` ("¿Ya se pusieron de acuerdo?"), `Acuerdo-confirmado` ("Resumen del acuerdo" → "Crear pedido") y `Pedido-pago` ("Tu pedido", "¿Cómo quieres pagar?"). La entrega usa los chips de `Pedido-entrega` y el día y la hora de `Apartar`.
- Trazabilidad: RF-30, RF-31, RF-34 · CU-17 · RN-06, RN-16, RN-17, RN-18 (Entregable 1).
- Decisiones de la usuaria (10-Nov-2026): resumen **sin IA** desde el chat; lugar de una lista del campus, más un detalle libre, con el edificio de la carrera recomendado primero; pago **solo en efectivo** al entregar (la transferencia llega con HU-55, D-01).

**Depende de:** `02-04` (piezas de la maqueta), `HU-20` (chat), `HU-17` (chat de una oferta aceptada), `HU-04` (carrera).

## Requisitos
1. **R1 · Entrada:** en el chat, el comprador toca "Resumir acuerdo" (junto a "¿Ya se pusieron de acuerdo?") y se abre "Resumen del acuerdo", con el diseño de `Acuerdo-esperando` pero **sin** lo de la IA. Si la conversación ya tiene un pedido abierto, el aviso cambia a "Pedido #MS-NNNN · Pendiente" y abre ese pedido. A quien vende se le explica que el pedido lo crea quien compra.
2. **R2 · Resumen:** viene lleno con el producto, o con la oferta aceptada, y su precio. El comprador elige la cantidad (de 1 a lo disponible), el punto de entrega (chips), un detalle opcional (hasta 120 caracteres), y el día y la hora. Mientras falte algo, "Crear pedido" queda deshabilitado y el dato faltante dice "No identificado" con "Agregar", como en la maqueta.
3. **R3 · Punto recomendado:** el punto que la API marca `suggested` (el edificio de su carrera) sale primero, con la etiqueta "Tu edificio".
4. **R4 · Crear:** "Crear pedido" crea el pedido **Pendiente** y abre `Pedido-pago` con el número `#MS-NNNN` y el paso "Pendiente" marcado. Un doble toque no crea dos (la API responde `already_open` y se abre ese).
5. **R5 · Pago:** en `Pedido-pago`, "Transferencia" sale deshabilitada con el texto de la maqueta "<vendedor> aún no registra su cuenta". "Efectivo al entregar" muestra "Así funciona" y "Confirmar pago en efectivo" lo registra. Después, la pantalla queda con efectivo elegido y el aviso de que el vendedor debe aceptar el pedido.
6. **R6 · Errores en español:** sin piezas, publicación ya no disponible, bloqueo, fecha u hora fuera del rango, o detalle rechazado por la moderación muestran el mensaje de la API y no pierden lo capturado.

## Diseño
- Feature nueva `lib/features/orders/` con `domain/` (`Order`, `MeetingPoint`, `OrderRepository`), `data/` (`HttpOrderRepository`) y `presentation/` (`OrderSummaryScreen`, `OrderPaymentScreen` y providers).
- El chat (`chat_screen.dart`) recibe el pedido abierto de la conversación (`GET /orders?conversationId=`) para decidir qué hace el aviso.
- Piezas de `lib/core/widgets/`: `SellStepLayout` no aplica; se usan `MusubiButton`, `Pressable`, chips y el selector de día y hora de `Apartar`, construido con los tokens de 02-04.

## Contratos
Filas M-08 de HU-23 en [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md), enlazadas desde `lib/core/network/api_paths.dart` (skill `api-contract`): puntos de entrega, crear, detalle, pedidos de una conversación y pago.

## Tests
- `test/features/orders/order_data_test.dart`: `HttpOrderRepository` con `FakeHttpAdapter` (mapeo, contrato de crear y pagar, `already_open` y estados).
- `test/features/orders/order_flow_test.dart`: el resumen (lleno con el producto, "No identificado", edificio recomendado primero, cantidad hasta lo disponible, crear, error sin perder datos, `already_open` y cerrar), el aviso del chat (pedido abierto, cancelado y quien vende) y "Tu pedido" (transferencia deshabilitada, pagar en efectivo, error al pagar, "Tu venta" y ayuda).
- `tool/screenshots_test.dart`: escenas `resumen-acuerdo` y `pedido-pago` en claro y oscuro, comparadas con la maqueta.

## Criterios
- [x] El comprador genera un pedido desde el detalle de un producto (por su chat) o desde una oferta aceptada (R1, R2). Desde un acuerdo confirmado: `NOTE (HU-34)`.
- [x] El pedido registra producto, cantidad, precio, lugar y fecha de entrega (R2, R3).
- [x] Todo pedido inicia como **Pendiente** (R4, RN-16).
- [x] La cantidad no puede superar la disponible (R2, RN-17) y no se pueden comprar productos propios (R1, RN-06).
- [x] El pago se realiza al momento de la entrega y queda registrado en el pedido (R5, RN-18 del Entregable 1).
- [x] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` 487/487 · critic PASS · capturas lado a lado con la maqueta.

## Límites
- `NOTE (HU-24)`: lo que ve y hace el vendedor con el pedido (aceptar, rechazar, completar y cancelar).
- `NOTE (HU-25)`: "Mis pedidos" en `Perfil`.
- `NOTE (HU-34)`: el resumen con la propuesta de la IA y la confirmación de los dos.
- `NOTE (HU-55)`: transferencia (`Pago-transferencia`, `Pago-validando`, `Pago-vendedor`) y código de entrega (`Pedido-efectivo`).
- "Comprar" en `Producto` sigue abriendo el chat, como en la maqueta.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026 (borrador ligero) · 10-Nov-2026 (detallado e implementado)
- **Detalle:** el pedido sale del chat sin IA, el punto de entrega es de una lista con un detalle libre y el edificio de la carrera se recomienda primero, y solo se paga en efectivo al entregar.
