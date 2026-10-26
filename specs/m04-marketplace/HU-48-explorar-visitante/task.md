# HU-48 — Explorar como visitante (tareas, app)

## T1 — Fase 1: vitrina, hoja "Crea tu cuenta" y regreso
- **Crear:** `lib/features/marketplace/`, `account_gate.dart` y `return_path.dart`; pestañas con la hoja.
- **Verificar:** `visitor_flow_test.dart`, `navigation_test.dart`, los self-tests y el dispositivo.
- **Estado:** ✅ Hecho (25-Oct-2026).

## T2 — Fase 2: catálogo público
- `NOTE (HU-06)`: `HttpCatalogRepository` sobre `GET /api/v1/products` (público, paginado, sin datos personales).
- `NOTE (HU-11)`: detalle del producto para visitantes.
- `NOTE (HU-15)`: "Se busca" completo.
- **Estado:** ⏳ Pendiente.
