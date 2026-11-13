# HU-45 — Calificar al comprador al terminar un pedido (tareas, app)

## T1 — Spec
- **Estado:** ✅ Hecho (12-Nov-2026), con HU-27.

## T2 — Datos
- **Prueba:** `http_reputation_repository_test.dart` (+5) y `order_data_test.dart` (+1).
- **Estado:** ✅ Hecho.

## T3 — `Calificar`
- **Prueba:** `test/features/reputation/rate_flow_test.dart` (9).
- **Estado:** ✅ Hecho.

## T4 — "Tu pedido" y `Perfil-vendedor`
- **Prueba:** `seller_profile_screen_test.dart` (+3) y `order_flow_test.dart`.
- **Estado:** ✅ Hecho.

## T5 — Evidencia y documentación
- **Estado:** ✅ Hecho: `flutter test` 643/643 · analyze 0 · critic PASS; capturas `calificar` y `perfil-vendedor-opiniones`.

## T6 — Prueba en el celular
- **Qué:** con la API `0.5.0-alpha.25` desplegada, calificar desde las dos cuentas y ver la reputación y las opiniones.
- **Estado:** ⏳ Por hacer.
