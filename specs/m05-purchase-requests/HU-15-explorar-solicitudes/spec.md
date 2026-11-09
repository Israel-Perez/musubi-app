# HU-15 — Explorar solicitudes publicadas (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-15 / SCRUM-37 / Sprint 4 (9 – 20 nov 2026) / M-05 / [musubi-api:HU-15](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m05-purchase-requests/HU-15-explorar-solicitudes)

## Contexto
Jira (SCRUM-37): Como **vendedor**, quiero **consultar y filtrar las solicitudes publicadas**, para **encontrar oportunidades de venta**.

- Maqueta: `Se-busca` (lupa y "Filtrar solicitudes") y `Se-busca-visitante` (cierra el "Se busca" de HU-48). "Yo tengo este producto" lo abre HU-16.
- Trazabilidad: RF-19 · CU-10 · RNF-19 · RNF-05.

**Depende de:** `02-01`, `02-03`, `02-04` (piezas de la maqueta), `HU-13` y `HU-48`.

## Requisitos
1. **R1 · Tablero con sesión (`Se-busca`):** "Se busca", el campus verificado, la lupa y "Filtrar". Cada boleto: iniciales o foto, nombre completo con la insignia, "carrera · hace 20 min · 2 ofertas", la pastilla "SE BUSCA", el producto, Presupuesto · Para el · Categoría y "Yo tengo este producto".
2. **R2 · Filtrar solicitudes:** hoja con Categoría (varias, con "Ver solicitudes"), Presupuesto ("Hasta $300", "$300 – $1,000", "Más de $1,000") y Fecha límite ("En 3 días o menos", "Esta semana"); el botón muestra cuántos filtros hay.
3. **R3 · Lupa:** "Busca solicitudes: bata, laptop…" filtra al escribir; cerrarla borra la búsqueda.
4. **R4 · Visitante (`Se-busca-visitante`):** encabezado rojo con el campus, "Entrar", "Tu campus lo pide. Tú lo tienes." y los tres pasos; "Lo que se busca hoy" con el nombre corto; "¿Necesitas algo?" con "Pedir algo". Ofrecer o pedir abre la hoja "Crea tu cuenta" y vuelve a "Se busca".
5. **R5 · Estados:** cargando, vacío ("Nadie ha pedido nada todavía" con "Pedir algo"), sin coincidencias ("No hay solicitudes con estos filtros…") y error con "Reintentar"; al final de la lista carga la página siguiente.
6. **R6 · Inicio:** la fila "Se busca" de Inicio sale del mismo tablero; si falla, Inicio se muestra sin ella.
7. **R7 · RNF-19:** la solicitud es un boleto (rojo claro, línea punteada con muescas y presupuesto al frente), distinto de la foto grande de un producto.

## Diseño
- `lib/features/purchase_requests/`:
  - `domain/wanted_board.dart` (`WantedBoardFilter`, `WantedBudget`, `WantedDeadline`, `WantedPage`);
  - `WantedRepository.board` en `HttpWantedRepository`;
  - `presentation/wanted_board_providers.dart` (filtros y páginas);
  - `wanted_board_screen.dart` y `wanted_board_cards.dart`.
- Piezas nuevas de 02-04: `MusubiMultiOptions` (marca cuadrada, `.opt-multi`), `CampusChip(onBrand:)`, los íconos `handshake` y `arrowDownUp` y el token `brandDeep` (`#B9141A`).
- `HttpCatalogRepository.homeFeed` pide `GET /wanted?limit=6` para "Se busca" de Inicio.

## Contratos
Fila `GET /api/v1/wanted` de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md), enlazada desde `ApiPaths.wanted`.

## Tests
- `test/features/purchase_requests/wanted_board_test.dart`: R1–R5 con el router real.
- `test/features/purchase_requests/wanted_data_test.dart`: consulta y mapeo del tablero (foto, carrera y visitante).
- `test/features/marketplace/http_catalog_repository_test.dart`: R6.
- `test/app/navigation_test.dart`: la pestaña del visitante.
- `tool/screenshots_test.dart`: `se-busca`, `se-busca-filtros`, `se-busca-lupa`, `se-busca-visitante` y `se-busca-visitante-scroll`.

## Criterios
- [x] Se listan las solicitudes **Activas** (R1, R4).
- [x] Se pueden filtrar por categoría y presupuesto, y además por fecha límite y palabras (R2, R3).
- [x] Las solicitudes se distinguen visualmente de los productos publicados (R7).
- [x] Capturas iguales a la maqueta (título a 77 pt, primer boleto a 114 pt contra 115 y "Lo que se busca hoy" a 333 pt en las dos).
- [x] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` 396/396 · critic PASS.

## Límites
- `NOTE (HU-16)`: "Yo tengo este producto" con sesión muestra un aviso hasta que llegue `Yo-tengo-vincular`/`Yo-tengo-oferta`.
- `NOTE (HU-18)`: "Coincide con tu …" en el boleto.
- Las iniciales no copian el gris de Fernanda en la maqueta: cada persona toma una de las 5 parejas de colores por su id.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026 (borrador) · 09-Nov-2026 (implementación)
- **Detalle:** filtros completos de la maqueta; con HU-15 cierra el "Se busca" del visitante (HU-48).
