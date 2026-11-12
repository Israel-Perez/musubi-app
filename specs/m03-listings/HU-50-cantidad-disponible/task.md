# HU-50 — Manejar la cantidad disponible de un producto (app, tareas)

## T1 — Detallar la spec
- **Estado:** ✅ Hecho (12-Nov-2026). Decisión de la usuaria: menú y "Reponer".

## T2 — Datos
- **Cambiar:** `setStock`, `ApiPaths.productStock` y el fake.
- **Verificar:** `http_listings_repository_test.dart` (+1).
- **Estado:** ✅ Hecho (12-Nov-2026).

## T3 — Pantalla
- **Cambiar:** `QuantityRow` compartido, "Cambiar piezas" y "Reponer" en `Mis-productos`.
- **Verificar:** `my_products_manage_test.dart` (+3).
- **Estado:** ✅ Hecho (12-Nov-2026).

## T4 — Capturas y documentación
- **Qué:** escenas `cambiar-piezas` y `mis-productos-agotados`; spec, plan y task; la fila de HU-50 en `docs/trazabilidad.md`; `Memoria.md`.
- **Estado:** ✅ Hecho (12-Nov-2026).

## Pendientes
- `NOTE (musubi-api:HU-52)`: un apartado vencido regresa la pieza solo.
