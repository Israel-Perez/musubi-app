# HU-07 — Editar o eliminar mis publicaciones (app, tareas)

## T1 — Detallar la spec
- **Qué:** conciliar la maqueta (`Mis-productos`, `Vender-2…4`) con las filas de `musubi-api:HU-07`.
- **Estado:** ✅ Hecho (10-Nov-2026). Decisiones de la usuaria: Pausar en el menú, piezas sin editar y dos PR apilados (HU-07 y luego HU-08).

## T2 — Datos
- **Cambiar:** `ListingsRepository` (`update`, `pause`, `resume` y `delete`), `HttpListingsRepository`, `ApiPaths` y el fake.
- **Verificar:** `test/features/listings/http_listings_repository_test.dart` (+4).
- **Estado:** ✅ Hecho (10-Nov-2026).

## T3 — Pantallas
- **Cambiar:**
  - `SellDraft` (modo edición) y `sell_edit.dart`;
  - `Vender-2…4` con `editing`;
  - 3 rutas;
  - el menú de `Mis-productos`.
- **Verificar:** `test/features/listings/my_products_manage_test.dart` (7). Mutación: sin la pausada en "Activos", `pausar y reactivar` queda en rojo.
- **Estado:** ✅ Hecho (10-Nov-2026).

## T4 — Capturas y documentación
- **Qué:**
  - escenas `mis-productos-menu`, `editar-publicacion` y `editar-publicacion-estado`;
  - spec, plan y task;
  - la fila de HU-07 en `docs/trazabilidad.md`;
  - `Memoria.md`.
- **Estado:** ✅ Hecho (10-Nov-2026).

## Pendientes
- `NOTE (musubi-api:HU-18)`: volver a buscar coincidencias al editar (lo hace la API).
- `NOTE (HU-08)`: "Marcar como vendido" y "Vendidos" llegan en el PR apilado de HU-08.
- `NOTE (HU-50)`: cambiar las piezas desde la lista ("Reponer").
