# HU-06 — Publicar un producto (app, tareas)

## T1 — Datos
- **Crear:** `features/listings/{domain,data}`, `marketplace/data/{http_catalog_repository,product_json}.dart` y las rutas en `api_paths.dart`.
- **Verificar:** `http_listings_repository_test.dart` y `http_catalog_repository_test.dart`.
- **Estado:** ✅ Hecho (27-Oct-2026).

## T2 — Flujo de venta
- **Crear:** `SellDraftNotifier`, las pantallas `sell_*`, `PublishOverlay`, `MyProductsScreen`, las rutas `/vender…` y los íconos.
- **Verificar:** `sell_flow_test.dart` y `sell_draft_test.dart`.
- **Estado:** ✅ Hecho (27-Oct-2026).

## T3 — Inicio real
- **Cambiar:** `catalogRepositoryProvider` usa `HttpCatalogRepository`; "Populares" se oculta sin vistas.
- **Verificar:** `home_screen_test.dart`.
- **Estado:** ✅ Hecho (27-Oct-2026).

## T4 — Evidencia
- **Capturas:** `publicar`, `vender-1…4` y `vender-listo` comparadas con la maqueta.
- **Teléfono:** probar en el celular contra AWS cuando el back esté desplegado.
- **Estado:** 🚧 En curso.

## Pendientes
- `NOTE (HU-13)`: "Publicar lo que necesito".
- `NOTE (HU-18)`: solicitudes que coinciden al publicar.
- `NOTE (HU-08)`: "Vendidos" y "Llevan tiempo sin venderse".
- `NOTE (HU-50)`: cambiar piezas desde "Mis productos".
- `NOTE (HU-49)`: "Populares".
- `NOTE (HU-53)`: guardar el borrador con los datos locales.
- `NOTE (HU-06)`: recuperar la foto si Android cierra la app con la cámara abierta.
