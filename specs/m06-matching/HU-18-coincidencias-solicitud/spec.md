# HU-18 — Ver coincidencias al publicar una solicitud (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-18 / SCRUM-40 / Sprint 5 (14 nov – 1 dic 2026) / M-06 / [musubi-api:HU-18](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m06-matching/HU-18-coincidencias-solicitud)

## Contexto
Jira (SCRUM-40): Como **comprador**, quiero **que al publicar mi solicitud el sistema me muestre productos ya publicados que coinciden**, para **no tener que buscarlos manualmente**.

- Maqueta: `Necesidad-publicada` ("Ya coinciden con lo que buscas": "Dentro de tu presupuesto" y "Modelo parecido").
- Decisiones de la usuaria (14-Nov-2026): exactas y parecidas.

**Depende de:** [musubi-api:HU-18](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m06-matching/HU-18-coincidencias-solicitud), `HU-13`.

## Requisitos
1. **R1:** al publicar, `Necesidad-publicada` muestra hasta 3 coincidencias de `GET /wanted/{id}/matches` y el total en el globo.
2. **R2:** cada una dice "Dentro de tu presupuesto" (exacta y en presupuesto), "Arriba de tu presupuesto" (exacta, hasta 20 % arriba) o "Modelo parecido" (parecida).
3. **R3:** si la API no responde o no hay coincidencias, la sección no sale.
4. **R4:** tocar una abre su detalle.

## Diseño
- `WantedMatch` (dominio), `WantedRepository.matches`, `HttpWantedRepository`, `wantedMatchesProvider`, `ApiPaths.wantedMatches`; `MatchFit` en `need_done_screen.dart`.

## Contratos
Fila `GET /api/v1/wanted/{id}/matches` de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md).

## Tests
- `test/features/purchase_requests/wanted_data_test.dart` → "coincidencias (HU-18)".
- `test/features/purchase_requests/need_flow_test.dart`: publicar y ver las dos etiquetas.
- Captura `necesidad-publicada`.

## Criterios
- [x] Se ven las coincidencias al publicar → `need_flow_test.dart`.
- [x] Exactas y parecidas con su etiqueta → `need_flow_test.dart` y captura.
- [x] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS.

## Límites
- "Ya hay 3 publicaciones parecidas" de `Necesidad-1` sigue con la búsqueda de HU-09.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026 (borrador ligero) · 14-Nov-2026 (detallado e implementado)
