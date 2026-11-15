# HU-55 — Pagar un pedido por transferencia o en efectivo (app, tareas)

## T1 — Spec
- **Estado:** ✅ Hecho (15-Nov-2026), con las decisiones de la usuaria.

## T2 — Datos
- **Qué:** `payment_models.dart`, el pago de HU-55 en `Order`, `OrderRepository`, `HttpOrderRepository`, `HttpPayoutRepository` y los providers.
- **Prueba:** `test/features/orders/payments_test.dart` (grupo de los repositorios HTTP y `Clabe`).
- **Estado:** ✅ Hecho.

## T3 — Pantallas
- **Qué:** `OrderPaymentScreen` por estado, `TransferScreen`, `payment_widgets.dart`, `PayoutAccountScreen`, la fila de `Ajustes`, los avisos y los íconos.
- **Prueba:** `test/features/orders/payments_test.dart` y `order_flow_test.dart`; capturas contra la maqueta.
- **Estado:** ✅ Hecho: `flutter test` 731, `analyze` 0 y critic PASS.

## T4 — Comprobante (NOTE (HU-55))
- **Qué:** "Adjuntar comprobante · opcional" y "Comprobante de Ana · Ver", con el almacenamiento privado de la API.
- **Estado:** ⏳ Por hacer (decisión de la usuaria del 15-Nov-2026: después).

## T5 — Prueba en el celular
- **Qué:** con la API `0.5.0-alpha.35` desplegada y la llave de cifrado en Parameter Store: registrar la cuenta, comprar por transferencia y en efectivo con el código.
- **Estado:** ⏳ Por hacer.
