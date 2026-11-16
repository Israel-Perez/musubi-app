# HU-52 — Apartar un producto y verificar la entrega con QR o código (tareas, app)

## T1 — Detallar la spec
- **Estado:** ✅ Hecho (15-Nov-2026), con las decisiones de la usuaria y la excepción de 00-01.

## T2 — Dominio y datos
- **Qué:** `reservation_models.dart` y `HttpReservationRepository`.
- **Prueba:** `test/features/orders/reservations_test.dart` (horas, QR y repositorio HTTP).
- **Estado:** ✅ Hecho.

## T3 — Pantallas
- **Qué:** `Apartar`, `Apartado-listo`, `Mis-apartados`, `Verificar-comprador`, `Apartado-verificado`, la tarjeta de `Perfil` y el aviso.
- **Prueba:** `reservations_test.dart` (flujos con el router real) y `android_config_test.dart`.
- **Estado:** ✅ Hecho.

## T4 — Evidencia y documentación
- **Qué:** capturas contra la maqueta, `docs/trazabilidad.md`, `AGENTS.md`, la constitución §6, 00-01 y `Memoria.md`.
- **Estado:** ✅ Hecho: format 0 · analyze 0 · `flutter test` 749 · critic PASS.

## T5 — Prueba en el celular
- **Qué:** con la API `0.5.0-alpha.36`: apartar, mostrar el QR, escanearlo con otro celular, escribir el código y entregar.
- **Estado:** ⏳ Por hacer.
