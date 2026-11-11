# HU-08 — Consultar el estado de mis productos (app, tareas)

## T1 — Detallar la spec
- **Qué:** conciliar la maqueta (`Mis-productos`) con las filas de `musubi-api:HU-08` y las decisiones del back.
- **Estado:** ✅ Hecho (10-Nov-2026).

## T2 — Datos
- **Cambiar:** `minePage`, `markSold`, `sold` y `soldAt`, `ApiPaths.productSold` y el fake (página por pestaña con conteos).
- **Verificar:** `http_listings_repository_test.dart` (+3). Mutación: sin leer `sold`, en rojo.
- **Estado:** ✅ Hecho (10-Nov-2026).

## T3 — Pantalla
- **Cambiar:** `MyProductsScreen` (conteos de la API, "Ver más", "Vendidos", diálogo y menú corto) y `myListingsTabProvider`.
- **Verificar:** `my_products_manage_test.dart` (+4).
- **Estado:** ✅ Hecho (10-Nov-2026).

## T4 — Capturas y documentación
- **Qué:** escenas `mis-productos-vendidos` y `marcar-vendido`; spec, plan y task; la fila de HU-08 en `docs/trazabilidad.md`; `Memoria.md`.
- **Estado:** ✅ Hecho (10-Nov-2026).

## Pendientes
- `NOTE (musubi-api:HU-52)`: "Reservada".
- `NOTE (HU-25)`: comprador y monto real en "Vendidos".
- `NOTE (HU-50)`: contador +/− y "Reponer".
