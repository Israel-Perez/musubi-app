# HU-14 — Editar, cerrar o cancelar mi solicitud (app, plan)

## Decisiones
- **"Cambiar" abre "Tu solicitud":** la maqueta no dibuja editar, cerrar ni cancelar. "Cambiar" ya era el control de la solicitud elegida, y la hoja es la misma de "Más opciones" del chat. Así no cambia la tarjeta.
- **Editar reutiliza `Necesidad-1…3`:** son los mismos datos y las mismas reglas; el encabezado dice "Editar solicitud" y no sale "Así funciona".
- **"Guardar" guarda los cambios desde cualquier paso:** al editar no hay borrador que conservar.
- **Otro borrador para editar:** no pisa un "Publicar lo que necesito" a medias.
- **Con ofertas, el producto y la categoría se ven pero no se cambian:** la API respondería `409 wanted.has_offers`; la app lo evita antes y explica por qué.
- **Confirmar antes de cerrar o cancelar:** las dos son definitivas (no hay "Reabrir").

## Archivos
- **Nuevos:**
  - `lib/features/purchase_requests/presentation/need_edit.dart`;
  - `test/features/purchase_requests/manage_wanted_test.dart`.
- **Cambian:**
  - `my_wanted_screen.dart`, `received_offers.dart`, `need_product_screen.dart`, `need_details_screen.dart`, `need_budget_screen.dart` y `wanted_providers.dart`;
  - `wanted_repository.dart`, `http_wanted_repository.dart`, `api_paths.dart`, `router.dart` y `sell_layout.dart`;
  - `test/helpers/fake_wanted.dart`, `wanted_data_test.dart`, `need_flow_test.dart` y `tool/screenshots_test.dart`.
- **Docs:** `docs/versionado.md` (igual a musubi-api: filas `0.5.0-alpha.12` y `alpha.13`), `docs/trazabilidad.md`, `AGENTS.md` y `Memoria.md`.
