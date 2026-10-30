# HU-10 — Filtrar por categoría y precio (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-10 / SCRUM-27 / Sprint 2 (12 – 23 oct 2026) / M-04 / [musubi-api:HU-10](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m04-marketplace/HU-10-filtrar-categoria-precio)

## Contexto
Jira (SCRUM-27): Como **comprador**, quiero **filtrar los resultados por categoría y precio**, para **descartar lo que no me sirve**.

- Maqueta: `Busqueda`, `Busqueda-filtros`, `Busqueda-vacia`.
- Trazabilidad: RF-13 · CU-06.
- Origen: Propuesta inicial §11.

**Depende de:** `02-01`, `02-03`, `02-04` (piezas de la maqueta), `HU-09`.

## Requisitos
1. Se puede filtrar por categoría.
2. Se puede filtrar por rango de precio.
3. Los filtros se combinan con la búsqueda por palabra clave.

RNF que aplican: se confirman al detallar.

## Diseño
- Feature `lib/features/marketplace/` con `domain/`, `data/` y `presentation/` (skill `vertical-slice`).
- Pantallas con las piezas de `lib/core/widgets/` y los tokens de 02-04, iguales a la maqueta.
- Consume las filas del back de HU-10. Mientras no existan: repositorio fake con `NOTE (musubi-api:HU-10)` (skill `deferred-scope-fakes`).

## Contratos
Filas de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) para HU-10, enlazadas desde `lib/core/network/api_paths.dart` (skill `api-contract`). Se listan al detallar.

## Tests
- `test/features//`: repositorio HTTP con `FakeHttpAdapter` (mapeo y errores en español).
- Widget tests por estado (carga, vacío, error y éxito) y por cada criterio de aceptación.
- `tool/screenshots_test.dart`: escenas de las pantallas, comparadas con la maqueta en claro y oscuro.

## Criterios
- [ ] Se puede filtrar por categoría.
- [ ] Se puede filtrar por rango de precio.
- [ ] Los filtros se combinan con la búsqueda por palabra clave.
- [ ] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS.

## Límites
- Spec ligera: el diseño, los contratos y las pruebas exactas se fijan al iniciar la HU (`plan.md`).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador (spec ligera)
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026
- **Detalle:** generada desde Jira, la maqueta y el modelo de datos para tener todo el backlog especificado (SCRUM-86, pedido del docente). Al iniciar la HU se completan `plan.md` y `task.md` y se resuelven las decisiones pendientes.
