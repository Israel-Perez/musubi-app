# HU-12 — Guardar una búsqueda sin resultados (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-12 / SCRUM-51 / Sprint 5 (14 nov – 1 dic 2026) / M-04 / [musubi-api:HU-12](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m04-marketplace/HU-12-guardar-busqueda)

## Contexto
Jira (SCRUM-51): Como **comprador**, quiero **que se conserve una búsqueda que no tuvo resultados**, para **recibir un aviso cuando aparezca un producto compatible**.

- Maqueta: `Busqueda-vacia`. "Mis alertas" no está en la maqueta (decisión de la usuaria del 14-Nov-2026: en `Ajustes` → Preferencias).

**Depende de:** [musubi-api:HU-12](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m04-marketplace/HU-12-guardar-busqueda), `HU-09`, `HU-13`, `HU-31`.

## Requisitos
1. **R1 · `Busqueda-vacia`:** con palabras y sin resultados, la pantalla de la maqueta: "Publicar lo que necesito" (con el nombre ya escrito), "Avísame cuando aparezca" y "Prueba con".
2. **R2 · Avísame:** guarda la búsqueda con sus filtros; el botón queda "Te avisaremos cuando aparezca" y avisa "Listo. Te avisamos cuando alguien lo publique."; si ya la tenía, "Ya tienes activa esta alerta". Sin sesión, la hoja "Crea tu cuenta".
3. **R3 · Mis alertas:** en `Ajustes`, la fila dice cuántas hay y abre la lista con filtros, vencimiento y "Quitar".
4. **R4 · El aviso** (`saved_search_match`) abre la publicación (destino `product` de HU-29).

## Diseño
- `SearchNothingFound` (`search_nothing_found.dart`), `SavedSearchesScreen`, `SavedSearchRepository` / `HttpSavedSearchRepository`, `savedSearchRepositoryProvider`, `mySavedSearchesProvider`, `AppRoutes.settingsAlerts`, `MusubiIcons.searchX`.

## Contratos
Filas `POST`, `GET` y `DELETE /api/v1/saved-searches` de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md).

## Tests
- `test/features/marketplace/search_screen_test.dart`: el vacío de la maqueta y el grupo "Avísame cuando aparezca (HU-12)".
- `test/features/marketplace/saved_searches_test.dart`: "Mis alertas" y `HttpSavedSearchRepository`.
- Capturas `busqueda-vacia`, `busqueda-vacia-alerta` y `mis-alertas`.

## Criterios
- [x] Sin resultados se ofrece guardar la búsqueda o pedirla → `search_screen_test.dart`.
- [x] Se consultan y se quitan → `saved_searches_test.dart`.
- [x] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026 (borrador ligero) · 14-Nov-2026 (detallado e implementado)
