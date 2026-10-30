# HU-27 — Calificar al vendedor al terminar un pedido (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-27 / SCRUM-46 / Sprint 3 (26 oct – 6 nov 2026) / M-13 / [musubi-api:HU-27](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m13-reputation/HU-27-calificar-vendedor)

## Contexto
Jira (SCRUM-46): Como **comprador**, quiero **calificar la experiencia al terminar un pedido**, para **ayudar a otros usuarios a decidir**.

- Maqueta: `Calificar`.
- Trazabilidad: RF-35, RF-36 · CU-19 · RN-24, RN-25, RN-26.
- Origen: Propuesta inicial §11.

**Depende de:** `02-01`, `02-03`, `02-04` (piezas de la maqueta), `HU-24`.

## Requisitos
1. Solo se puede calificar un pedido **Completado**, una sola vez por pedido (RN-24).
2. La calificación usa una escala de 1 a 5 (RN-25, propuesta) y permite un comentario opcional.
3. La reputación se muestra como promedio junto con el número de calificaciones, en el perfil y en las publicaciones (RF-36).

RNF que aplican: se confirman al detallar.

## Diseño
- Feature `lib/features/reputation/` con `domain/`, `data/` y `presentation/` (skill `vertical-slice`).
- Pantallas con las piezas de `lib/core/widgets/` y los tokens de 02-04, iguales a la maqueta.
- Consume las filas del back de HU-27. Mientras no existan: repositorio fake con `NOTE (musubi-api:HU-27)` (skill `deferred-scope-fakes`).

## Contratos
Filas de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) para HU-27, enlazadas desde `lib/core/network/api_paths.dart` (skill `api-contract`). Se listan al detallar.

## Tests
- `test/features//`: repositorio HTTP con `FakeHttpAdapter` (mapeo y errores en español).
- Widget tests por estado (carga, vacío, error y éxito) y por cada criterio de aceptación.
- `tool/screenshots_test.dart`: escenas de las pantallas, comparadas con la maqueta en claro y oscuro.

## Criterios
- [ ] Solo se puede calificar un pedido **Completado**, una sola vez por pedido (RN-24).
- [ ] La calificación usa una escala de 1 a 5 (RN-25, propuesta) y permite un comentario opcional.
- [ ] La reputación se muestra como promedio junto con el número de calificaciones, en el perfil y en las publicaciones (RF-36).
- [ ] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS.

## Límites
- Spec ligera: el diseño, los contratos y las pruebas exactas se fijan al iniciar la HU (`plan.md`).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador (spec ligera)
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026
- **Detalle:** generada desde Jira, la maqueta y el modelo de datos para tener todo el backlog especificado (SCRUM-86, pedido del docente). Al iniciar la HU se completan `plan.md` y `task.md` y se resuelven las decisiones pendientes.
