# HU-28 — Reportar contenido o usuarios sospechosos (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-28 / SCRUM-57 / Sprint 5 (23 nov – 4 dic 2026) / M-13 / [musubi-api:HU-28](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m13-reputation/HU-28-reportar-contenido)

## Contexto
Jira (SCRUM-57): Como **usuario**, quiero **reportar una publicación, solicitud o usuario sospechoso**, para **mantener segura la comunidad**.

- Maqueta: sin pantalla propia. Se diseña con la guía de estilo de la maqueta; el lineamiento 4 permite agregar, nunca quitar.
- Trazabilidad: RF-37 · CU-20 · RN-23, RN-27.
- Origen: Propuesta inicial §11.

**Depende de:** `02-01`, `02-03`, `02-04` (piezas de la maqueta), `HU-05`, `HU-11`.

## Requisitos
1. Se puede reportar una publicación, solicitud, oferta, mensaje o usuario, indicando el motivo.
2. El reporte llega a la revisión del administrador (HU-39).

RNF que aplican: se confirman al detallar.

## Diseño
- Feature `lib/features/reputation/` con `domain/`, `data/` y `presentation/` (skill `vertical-slice`).
- Pantallas con las piezas de `lib/core/widgets/` y los tokens de 02-04, iguales a la maqueta.
- Consume las filas del back de HU-28. Mientras no existan: repositorio fake con `NOTE (musubi-api:HU-28)` (skill `deferred-scope-fakes`).

## Contratos
Filas de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) para HU-28, enlazadas desde `lib/core/network/api_paths.dart` (skill `api-contract`). Se listan al detallar.

## Tests
- `test/features//`: repositorio HTTP con `FakeHttpAdapter` (mapeo y errores en español).
- Widget tests por estado (carga, vacío, error y éxito) y por cada criterio de aceptación.
- Widget tests de las pantallas nuevas (sin escena de maqueta).

## Criterios
- [ ] Se puede reportar una publicación, solicitud, oferta, mensaje o usuario, indicando el motivo.
- [ ] El reporte llega a la revisión del administrador (HU-39).
- [ ] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS.

## Límites
- Decisión pendiente (Jira): Se ubica en Sprint 5 junto con el módulo de administración y moderación.
- Spec ligera: el diseño, los contratos y las pruebas exactas se fijan al iniciar la HU (`plan.md`).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador (spec ligera)
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026
- **Detalle:** generada desde Jira, la maqueta y el modelo de datos para tener todo el backlog especificado (SCRUM-86, pedido del docente). Al iniciar la HU se completan `plan.md` y `task.md` y se resuelven las decisiones pendientes.
