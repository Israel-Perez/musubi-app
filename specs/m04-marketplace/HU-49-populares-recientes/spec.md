# HU-49 — Ver populares y recién publicados (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-49 / SCRUM-69 / por asignar / M-04 / [musubi-api:HU-49](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m04-marketplace/HU-49-populares-recientes)

## Contexto
Jira (SCRUM-69): Como **comprador**, quiero **ver lo más popular de hoy y de la semana y lo recién publicado en mi campus**, para **descubrir productos sin tener que buscarlos**.

- Maqueta: `Inicio`, `Recien-publicados`, `Recien-publicados-antiguas`.
- Trazabilidad: sin RF/RNF en Jira (historia que nació de la maqueta, SCRUM-75).
- Origen: maqueta (sección 3, G-02).

**Depende de:** `02-01`, `02-03`, `02-04` (piezas de la maqueta), `HU-11`.

## Requisitos
1. Inicio muestra "Populares" con un selector Hoy / Semana, calculado por las vistas de mi campus.
2. "Recién publicados" lista los productos disponibles del más nuevo al más antiguo y tiene la opción "Más antiguas".
3. Los listados están paginados y se pueden servir desde caché (lineamientos 9 y 15).

RNF que aplican: se confirman al detallar.

## Diseño
- Feature `lib/features/marketplace/` con `domain/`, `data/` y `presentation/` (skill `vertical-slice`).
- Pantallas con las piezas de `lib/core/widgets/` y los tokens de 02-04, iguales a la maqueta.
- Consume las filas del back de HU-49. Mientras no existan: repositorio fake con `NOTE (musubi-api:HU-49)` (skill `deferred-scope-fakes`).

## Contratos
Filas de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) para HU-49, enlazadas desde `lib/core/network/api_paths.dart` (skill `api-contract`). Se listan al detallar.

## Tests
- `test/features//`: repositorio HTTP con `FakeHttpAdapter` (mapeo y errores en español).
- Widget tests por estado (carga, vacío, error y éxito) y por cada criterio de aceptación.
- `tool/screenshots_test.dart`: escenas de las pantallas, comparadas con la maqueta en claro y oscuro.

## Criterios
- [ ] Inicio muestra "Populares" con un selector Hoy / Semana, calculado por las vistas de mi campus.
- [ ] "Recién publicados" lista los productos disponibles del más nuevo al más antiguo y tiene la opción "Más antiguas".
- [ ] Los listados están paginados y se pueden servir desde caché (lineamientos 9 y 15).
- [ ] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS.

## Límites
- Decisión pendiente (Jira): qué cuenta como "vista" para la popularidad (abrir el detalle) y cada cuánto se recalcula.
- Spec ligera: el diseño, los contratos y las pruebas exactas se fijan al iniciar la HU (`plan.md`).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador (spec ligera)
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026
- **Detalle:** generada desde Jira, la maqueta y el modelo de datos para tener todo el backlog especificado (SCRUM-86, pedido del docente). Al iniciar la HU se completan `plan.md` y `task.md` y se resuelven las decisiones pendientes.
