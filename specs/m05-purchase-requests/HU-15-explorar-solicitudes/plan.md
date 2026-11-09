# HU-15 — Explorar solicitudes publicadas (app, plan)

## Decisiones
- **Una sola pestaña, dos pantallas:** con sesión `Se-busca` y sin ella `Se-busca-visitante`, como hace Inicio. El repositorio usa el cliente con sesión: sin token la API responde como a un visitante.
- **Filtros que viven con la pestaña:** se conservan al volver a ella (como `sbState` de la maqueta) y se reinician al entrar o salir de la cuenta.
- **Rangos de presupuesto en la app:** las opciones de la maqueta se traducen a `minBudgetCents`/`maxBudgetCents`; la API no fija los rangos.
- **"Otro" al final de Categoría:** las solicitudes pueden ser de "Otro" (HU-13) aunque la lista de la maqueta no lo traiga.
- **La lupa espera 300 ms:** así no se pide una página por cada letra.
- **"Se busca" de Inicio no tumba Inicio:** si el tablero falla, la sección sale vacía y el resto de Inicio sigue.
- **"Yo tengo este producto" con sesión:** aviso "Muy pronto…" hasta HU-16, que sigue en el sprint.

## Archivos
- **Nuevos:**
  - `domain/wanted_board.dart`;
  - `presentation/wanted_board_providers.dart`, `wanted_board_screen.dart` y `wanted_board_cards.dart`;
  - `test/features/purchase_requests/wanted_board_test.dart`.
- **Cambian:**
  - `wanted_models.dart`, `wanted_repository.dart`, `http_wanted_repository.dart` y `wanted_providers.dart`;
  - `musubi_panel.dart` (`MusubiMultiOptions`), `musubi_icons.dart`, `musubi_tokens.dart` y `campus_chip.dart`;
  - `home_feed.dart`, `home_cards.dart` y `http_catalog_repository.dart`;
  - `router.dart`, `tool/screenshots_test.dart` y `test/helpers/fake_wanted.dart`.

## Validación
- format, analyze, test y critic.
- Capturas contra la maqueta (Edge headless con `#sesion.Se-busca` y `#nuevo.Se-busca-visitante`).
- En el celular cuando se despliegue la API `0.5.0-alpha.9`.
