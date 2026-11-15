# HU-55 — Pagar un pedido por transferencia o en efectivo (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-55 / SCRUM-72 / Sprint 5 (14 nov – 1 dic 2026) / M-08 / [musubi-api:HU-55](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m08-orders/HU-55-pago-transferencia-efectivo)

## Contexto
Jira (SCRUM-72): Como **comprador**, quiero **pagar un pedido por transferencia a la cuenta verificada del vendedor o en efectivo al recibirlo**, para **cerrar la compra sin comisiones**.

- Maqueta: `Pedido-pago`, `Pago-transferencia`, `Pago-validando`, `Pago-vendedor`, `Pedido-entrega`, `Pedido-efectivo` y `Cuenta-pagos` (y la fila de `Ajustes`).
- Origen: maqueta (secciones 9 y 10). Decisión D-01: el pago de la maqueta reemplaza a HU-43 (Mercado Pago). Musubi no procesa el dinero.
- **Decisiones de la usuaria (15-Nov-2026):**
  - A las 24 h sin confirmar se le recuerda a quien vende, sin cancelar el pedido (lo hace la API).
  - Solo se pide la CLABE: la tarjeta negra muestra el banco, la CLABE y el titular; no se pide el número de tarjeta.
  - "Adjuntar comprobante · opcional" queda para después (`NOTE (HU-55)`).

**Depende de:** [musubi-api:HU-55](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m08-orders/HU-55-pago-transferencia-efectivo), `HU-23` y `HU-24` (`Tu pedido`), `HU-31` (avisos).

## Requisitos
1. **R1 · `Pedido-pago`:**
   - Si quien vende tiene cuenta, "Transferencia" sale elegida con el chip verde "Valeria tiene su cuenta registrada"; si no, sale deshabilitada como antes.
   - Las dos opciones se tocan para elegir y "Así funciona" cambia con la opción.
   - El botón es "Ver datos para transferir" (registra la transferencia y abre `Pago-transferencia`) o "Confirmar pago en efectivo".
2. **R2 · `Pago-transferencia`:**
   - "Transfiere exactamente $450.00" (con copiar).
   - La tarjeta negra con banco, CLABE completa (con copiar), titular y "Verificado".
   - "Concepto · escríbelo tal cual" (con copiar) y el aviso de no transferir a cuentas del chat.
   - "Captura la referencia" (4 a 30 letras o números) y "Enviar referencia a Valeria".
3. **R3 · `Pago-validando`:**
   - Con la referencia enviada, quien compra ve "Pendiente · Validando pago", "Valeria está validando tu pago", "Tu transferencia" (monto, para, banco, referencia y concepto) y "Mensaje a Valeria".
   - Si quien vende dijo "Todavía no me llega", lo dice y se puede cancelar.
4. **R4 · `Pago-vendedor`:**
   - "Ana dice que ya te transfirió", "Debe llegarte $450.00 · Por validar" y "Búscalo en la app de tu banco", con la cuenta enmascarada "BBVA •••• 9134".
   - El aviso de confirmar solo con el dinero visible, "Sí, me llegó el pago" (acepta el pedido) y "Todavía no me llega".
5. **R5 · `Pedido-entrega`:** con el pedido confirmado, la franja verde "Pago validado · $450 / Transferencia · Ref. 4829173".
6. **R6 · `Pedido-efectivo`:**
   - Quien compra ve "Pagas en efectivo al recibir · Lleva el monto exacto", "TU CÓDIGO DE ENTREGA · Solo tú lo ves" con sus 4 dígitos, "Al momento de la entrega" y "Mensaje a Valeria".
   - Quien vende escribe el código ("Código de entrega", 4 cajas, intentos que quedan) y "Confirmar entrega" completa el pedido y abre `Calificar`.
   - Sin intentos (o en un pedido de antes de HU-55), los dos botones de HU-24.
7. **R7 · `Cuenta-pagos`:**
   - "Cuenta para recibir pagos" desde `Ajustes` ("BBVA ···· 4829" o "Agregar").
   - La tarjeta con el banco, la CLABE enmascarada y el titular "A tu nombre".
   - "Titular de la cuenta" (prellenado con mi nombre) y "Banco", que se llena con los 3 primeros dígitos.
   - "CLABE interbancaria": dígito verificador al escribir; la API vuelve a validar.
   - "Guardar cuenta" y "Quitar cuenta". Sin llave en la API, no se puede guardar (RNF-15).
8. **R8 · Avisos:** `transfer_reported`, `transfer_reminder` y `transfer_not_received` con su ícono; abren el pedido.

## Diseño
- `lib/features/orders/domain/payment_models.dart`: `TransferDetails`, `PayoutAccount`, `PayoutStatus`, `PayoutBank`, `Clabe` y `PayoutRepository`.
- `Order`: el pago de HU-55 (`paysTransfer`, `transferReference`, `transferReportedAt`, `transferNotReceivedAt`, `transferValidatedAt`, `deliveryCode` y `codeAttemptsLeft`).
- `OrderRepository`: `payTransfer`, `transfer`, `reportTransfer`, `transferNotReceived` y `deliveryCode`.
- `HttpOrderRepository` y `HttpPayoutRepository`; providers `payoutRepositoryProvider`, `payoutStatusProvider`, `payoutBanksProvider` y `transferProvider`.
- Pantallas:
  - `TransferScreen` (`AppRoutes.transfer`) y `PayoutAccountScreen` (`AppRoutes.settingsPayouts`);
  - `payment_widgets.dart` (`ValidatingView`, `SellerTransferView`, `PaymentBanner`, `DeliveryCodeCard`, `HandoverChecklist` y `DeliveryCodeEntry`);
  - `OrderPaymentScreen` elige el bloque según el estado.
- Íconos de la maqueta: `landmark`, `copy` y `shield`.

## Contratos
Filas de M-08 y "Cuenta para recibir pagos" de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md): `ApiPaths.orderTransfer`, `orderTransferNotReceived`, `orderDeliveryCode`, `payoutBanks` y `payoutAccount`.

## Tests
- `test/features/orders/payments_test.dart`:
  - `Pedido-pago` con transferencia, `Pago-transferencia` → `Pago-validando` y "todavía no me llega".
  - `Pago-vendedor`, el código de quien compra, el código de quien vende y `Cuenta-pagos`.
  - `Clabe` y los dos repositorios HTTP.
- `test/features/orders/order_flow_test.dart`: los pasos de "Así funciona" y la captura del código al aceptar en efectivo.
- Capturas: `pedido-pago-transferencia`, `pago-transferencia`, `pago-validando`, `pago-vendedor`, `pedido-entrega-transferencia`, `pedido-efectivo`, `tu-venta-codigo`, `cuenta-pagos` y `ajustes`.

## Criterios
- [x] El vendedor registra su CLABE (validada y guardada cifrada por la API) y se muestra enmascarada → `payments_test.dart` (Cuenta-pagos), captura `cuenta-pagos` y `ajustes`.
- [x] Por transferencia, el comprador ve la cuenta y la referencia; el vendedor valida y el pedido pasa a Confirmado → `payments_test.dart`, capturas `pago-*` y `pedido-entrega-transferencia`.
- [x] En efectivo, el comprador ve su código de 4 dígitos y el vendedor lo captura para completar → `payments_test.dart`, capturas `pedido-efectivo` y `tu-venta-codigo`.
- [x] Musubi no cobra comisión ni procesa el dinero → ayuda de `Tu pedido` y de `Pago-transferencia`.
- [x] Solo las partes ven los datos de pago → la API (`PaymentsAuthTests`); la app solo pide `GET /orders/{id}/transfer` del pedido abierto.
- [x] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` 731 · critic PASS.

## Límites
- `NOTE (HU-55)`: "Adjuntar comprobante · opcional" (`Pago-transferencia`) y "Comprobante de Ana · Ver" (`Pago-vendedor`).
- La maqueta usa la tarjeta de débito en `Pago-transferencia`; la app muestra la CLABE (decisión de la usuaria).
- `Pedido-entrega` de la maqueta trae un mapa del campus; la app conserva la tarjeta del pedido con el punto de entrega (HU-44).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026 (borrador ligero) · 15-Nov-2026 (detallado e implementado, con las decisiones de la usuaria)
