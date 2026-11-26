# HU-42 — Consultar indicadores de uso (tareas)

## T1 — Detallar la spec
- **Estado:** ✅ Hecho (25-Nov-2026).

## T2 — Dominio y datos
- **Qué:** los modelos, `indicators(period)` y `display`.
- **Prueba:** `http_admin_repository_test.dart`.
- **Estado:** ✅ Hecho.

## T3 — Pantalla
- **Qué:** "Indicadores de uso" con los dos periodos, las áreas y las tarjetas; la fila en `Ajustes`.
- **Prueba:** `admin_indicators_test.dart` y `test/integration/admin_flow_test.dart`.
- **Estado:** ✅ Hecho.

## T4 — Prueba en el celular
- **Qué:** con la API `0.5.0-alpha.48` desplegada, abrir "Indicadores de uso" con la cuenta del equipo, cambiar a "Último mes" y revisar que los números tengan sentido.
- **Estado:** ⏳ Por hacer (siguiente lote de Google Play).
