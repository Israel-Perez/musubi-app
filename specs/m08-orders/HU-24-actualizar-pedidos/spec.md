# HU-24 — Aceptar y actualizar mis pedidos (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-24 / SCRUM-43 / Sprint 4 (9 – 20 nov 2026) / M-08 / [musubi-api:HU-24](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m08-orders/HU-24-actualizar-pedidos)

## Contexto
Jira (SCRUM-43): Como **vendedor**, quiero **aceptar y actualizar el estado de mis pedidos**, para **llevar control de las entregas**.

- Maqueta:
  - `Pedido-pago`: el stepper de cuatro estados y la tarjeta del pedido.
  - `Pedido-entrega`: "Confirmar entrega" y la nota "Revisa que … funcione antes de confirmar".
  - `Pedido-efectivo`: "Cancelar pedido" en rojo con el ícono `circle-x`.
- La maqueta no tiene una pantalla para que quien vende acepte o rechace. "Tu venta" reúne las mismas piezas:
  - el botón rojo "Aceptar pedido" (56 px, ícono `circle-check`);
  - "Rechazar pedido" con el estilo de "Cancelar pedido";
  - la hoja de motivos con las opciones planas de `reportSheet` (HU-28).
- Trazabilidad: RF-31, RF-33, RF-34 · CU-18 · RN-16, RN-19, RN-20.
- Decisiones de la usuaria (11-Nov-2026): para completar el pedido confirman **las dos partes**, solo se acepta con el pago elegido y el motivo sale de una lista fija.

**Depende de:** `02-04` (piezas de la maqueta), `HU-23` ("Tu pedido"), `HU-31` (avisos) y la API de HU-24.

## Requisitos
1. **R1 · Aceptar ("Tu venta"):** con el pedido pendiente, quien vende ve "Aceptar pedido".
   - Mientras quien compra no elija el pago, el botón sale atenuado y el aviso dice "Ana aún no elige cómo pagar. Podrás aceptar el pedido cuando lo elija."
   - Al aceptar, el pedido pasa a Confirmado y aparece "Pedido aceptado. Le avisamos a Ana.".
2. **R2 · Rechazar o cancelar:** "Rechazar pedido" (quien vende, pendiente) o "Cancelar pedido" (cualquiera, pendiente o confirmado) abre la hoja de motivos. Cada parte ve solo los suyos:
   - quien compra: "Ya no lo necesito";
   - quien vende: "Ya no tengo el producto";
   - los dos: "No nos pusimos de acuerdo", "No puedo en la fecha acordada", "La otra persona no llegó" y "Otro motivo".

   Elegir un motivo cancela el pedido.
3. **R3 · Confirmar la entrega (RN-19):** con el pedido confirmado, quien compra ve "Confirmar entrega" con la nota "Revisa el producto antes de confirmar la entrega.", y quien vende ve "Marcar como entregado".
   - Después de confirmar: "Ya confirmaste la entrega. Falta que Valeria la confirme.".
   - Si la otra parte ya confirmó, el aviso lo dice. Con las dos confirmaciones, el pedido queda Completado.
4. **R4 · Cómo terminó:** un pedido completado dice "Pedido completado. ¡Gracias por usar Musubi!".
   - Uno cancelado dice quién y por qué: "Valeria canceló el pedido: La otra persona no llegó.".
   - Sin acciones abiertas, el botón principal es "Volver al chat".
5. **R5 · Errores:** si la API rechaza una acción (por ejemplo, ya no hay piezas), aparece su mensaje en español y el botón se puede volver a tocar.
6. **R6 · Avisos:** la pantalla Notificaciones muestra los cuatro avisos nuevos con su ícono:
   - pedido aceptado o completado: `circle-check` verde;
   - la otra parte entregó o recibió: `package`;
   - cancelado: `circle-x` rojo.

   Tocarlos abre el pedido.

## Diseño
- **`OrderRepository`:** `accept`, `cancel(id, CancelReason)` y `confirmHandover`. Las rutas son `ApiPaths.orderAccept`, `orderCancel` y `orderHandover`.
- **Dominio:**
  - `Order` agrega `buyerConfirmed`, `sellerConfirmed`, `cancellation` (`OrderCancellation`), `iConfirmed`, `otherName` y `copyWith`.
  - El enum `CancelReason` lleva el código de la API, el texto y las listas por rol.
- **`OrderPaymentScreen`:** el botón principal, el aviso y "Rechazar"/"Cancelar pedido" dependen del estado y de quién mira. Cada acción gira su botón y bloquea las demás.
- **Ícono nuevo:** `MusubiIcons.circleX`.

## Contratos
Filas "M-08" de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md): `POST /orders/{id}/accept`, `/cancel` y `/handover`, más los campos nuevos de `OrderResponse` (`handover`, `cancellation`).

## Tests
- `test/features/orders/order_data_test.dart`: las tres rutas, el cuerpo `{ reason }`, el mapeo de `handover` y `cancellation`, las listas de motivos y un error de la API.
- `test/features/orders/order_flow_test.dart`, grupo "Aceptar y actualizar mis pedidos (HU-24)", 8 pruebas:
  - aceptar, y aceptar sin pago;
  - rechazar y cancelar, cada uno con sus motivos;
  - confirmar la entrega y completar el pedido;
  - error y reintento, y un pedido cancelado.
- `tool/screenshots_test.dart`: escenas `tu-venta`, `pedido-entrega` y `pedido-cancelar` (claro y oscuro).

## Criterios
- [x] El vendedor acepta o rechaza pedidos **Pendientes**; al aceptarlo pasa a **Confirmado** (R1, R2).
- [x] Los estados del pedido son **Pendiente**, **Confirmado**, **Completado** y **Cancelado** (stepper de `Pedido-pago`, R4).
- [x] El pedido pasa a **Completado** cuando ambas partes confirman la entrega (R3).
- [x] Cualquiera de las partes puede cancelar antes de completar, indicando el motivo (R2).
- [x] Si la cantidad llega a cero, la publicación pasa a **Vendida**. Lo hace la API; la app lo muestra en "Mis productos" (HU-08).
- [x] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS.
- [ ] Prueba en el celular con la API desplegada (`alpha.20`).

## Límites
- `NOTE (HU-27)`: "Calificar" al completarse (`Calificar`).
- `NOTE (HU-52)`: el código de entrega reemplaza el "Marcar como entregado" de quien vende.
- `NOTE (HU-55)`: validar la transferencia (`Pago-vendedor`) antes de aceptar.
- `NOTE (HU-25)`: "Mis pedidos", la lista por estado.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026 (borrador ligero) · 11-Nov-2026 (detallado e implementado)
- **Detalle:** las acciones viven en "Tu pedido"/"Tu venta". La maqueta no tiene pantalla de aceptar; se arma con sus piezas.
