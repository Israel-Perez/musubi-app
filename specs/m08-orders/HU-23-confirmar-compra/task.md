# HU-23 — Confirmar la compra de un producto (tareas)

## T1 — Detallar la spec
- **Qué:** decisiones de la usuaria (sin IA, lugar de una lista más un detalle, solo efectivo) y `plan.md`.
- **Estado:** ✅ Hecho (10-Nov-2026).

## T2 — Dominio y datos
- **Qué:** modelos, `HttpOrderRepository` y `test/features/orders/order_data_test.dart`.
- **Estado:** ✅ Hecho.

## T3 — Pantallas
- **Qué:** "Resumen del acuerdo" (con los paneles de cantidad, entrega y fecha), "Tu pedido" (`Pedido-pago`), el aviso del chat y la ruta `/pedido/:id`, con `test/features/orders/order_flow_test.dart`.
- **Estado:** ✅ Hecho. `flutter test` 487/487.

## T4 — Evidencia y documentación
- **Qué:** capturas comparadas con la maqueta, `docs/trazabilidad.md`, `docs/versionado.md` (`0.5.0-alpha.15`), `AGENTS.md` y `Memoria.md`.
- **Estado:** ✅ Hecho. Falta la prueba en el celular con la API desplegada.

## Pendientes con dueño
- `NOTE (HU-24)`: lo que hace quien vende con el pedido.
- `NOTE (HU-25)`: "Mis pedidos".
- `NOTE (HU-34)`: el resumen con la propuesta de la IA y la confirmación de los dos.
- `NOTE (HU-55)`: transferencia y código de entrega.
