# HU-24 — Aceptar y actualizar mis pedidos (tareas, app)

## T1 — Detallar la spec
- **Estado:** ✅ Hecho (11-Nov-2026), con las decisiones de la usuaria sobre RN-19, el pago y los motivos.

## T2 — Datos
- **Qué:** `CancelReason`, `OrderCancellation`, `Order.copyWith`, las tres rutas y el mapeo HTTP.
- **Prueba:** `test/features/orders/order_data_test.dart` (4 pruebas nuevas, 11 en total).
- **Estado:** ✅ Hecho.

## T3 — Pantalla
- **Qué:**
  - "Aceptar pedido", "Rechazar pedido" o "Cancelar pedido" con la hoja de motivos.
  - "Confirmar entrega" o "Marcar como entregado".
  - El aviso de cada estado y la nota de revisar el producto.
  - Los íconos de Notificaciones.
- **Prueba:** `test/features/orders/order_flow_test.dart`, grupo HU-24 (8 pruebas).
- **Capturas:** `tu-venta`, `pedido-entrega` y `pedido-cancelar`, en claro y oscuro.
- **Estado:** ✅ Hecho.

## T4 — Documentación
- **Qué:** `docs/trazabilidad.md`, `docs/versionado.md` (sección compartida) y `Memoria.md`.
- **Estado:** ✅ Hecho.

## T5 — Prueba en el celular
- **Qué:** con la API `0.5.0-alpha.20` desplegada (`infra-up` con `db/019`), el flujo completo con dos cuentas.
- **Estado:** ⏳ Por hacer.
