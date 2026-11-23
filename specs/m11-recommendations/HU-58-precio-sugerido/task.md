# HU-58 — Ver un precio sugerido y saber si un precio es bueno (tareas, app)

## T1 — Detallar la spec
- **Estado:** ✅ Hecho (23-Nov-2026).

## T2 — Datos
- **Qué:** `suggestPrice`, `estimate`, sus modelos y providers.
- **Prueba:** `test/features/listings/http_listings_repository_test.dart` y `test/features/marketplace/comparison_test.dart`.
- **Estado:** ✅ Hecho.

## T3 — Pantallas
- **Qué:** "Precio sugerido" en `Vender-3` y la estimación en "Compara antes de comprar".
- **Prueba:** `test/features/listings/sell_flow_test.dart`, `test/features/marketplace/product_screen_test.dart` y `test/integration/sell_flow_test.dart`.
- **Estado:** ✅ Hecho.

## T4 — Prueba en el celular
- **Qué:** con la API `0.5.0-alpha.44` y precios del campus: la sugerencia al publicar y al editar, y la estimación en `Producto`.
- **Estado:** ⏳ Por hacer (siguiente lote de Google Play).
