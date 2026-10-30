# HU-45 — Calificar al comprador al terminar un pedido (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-45 / SCRUM-50 / Sprint 3 (26 oct – 6 nov 2026) / M-13 / [musubi-api:HU-45](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m13-reputation/HU-45-calificar-comprador)

## Contexto
Jira (SCRUM-50): Como **vendedor**, quiero **calificar al comprador al terminar un pedido**, para **que la reputación refleje el comportamiento de ambas partes**.

- Maqueta: `Calificar`.
- Trazabilidad: RF-35, RF-36 · RN-24 · Entregable 1 §7 (calificación mutua).
- Origen: Entregable 1 §7 — historia nueva, no estaba en la lista original.

**Depende de:** `02-01`, `02-03`, `02-04` (piezas de la maqueta), `HU-24`.

## Requisitos
1. Al completarse un pedido, el vendedor puede calificar al comprador con la misma escala y un comentario opcional.
2. Solo una calificación por pedido.
3. La reputación del usuario considera las calificaciones recibidas como comprador y como vendedor.

RNF que aplican: se confirman al detallar.

## Diseño
- Feature `lib/features/reputation/` con `domain/`, `data/` y `presentation/` (skill `vertical-slice`).
- Pantallas con las piezas de `lib/core/widgets/` y los tokens de 02-04, iguales a la maqueta.
- Consume las filas del back de HU-45. Mientras no existan: repositorio fake con `NOTE (musubi-api:HU-45)` (skill `deferred-scope-fakes`).

## Contratos
Filas de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) para HU-45, enlazadas desde `lib/core/network/api_paths.dart` (skill `api-contract`). Se listan al detallar.

## Tests
- `test/features//`: repositorio HTTP con `FakeHttpAdapter` (mapeo y errores en español).
- Widget tests por estado (carga, vacío, error y éxito) y por cada criterio de aceptación.
- `tool/screenshots_test.dart`: escenas de las pantallas, comparadas con la maqueta en claro y oscuro.

## Criterios
- [ ] Al completarse un pedido, el vendedor puede calificar al comprador con la misma escala y un comentario opcional.
- [ ] Solo una calificación por pedido.
- [ ] La reputación del usuario considera las calificaciones recibidas como comprador y como vendedor.
- [ ] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS.

## Límites
- Decisión pendiente (Jira): Resuelve la observación 8 del Anexo A. Pendiente: si la reputación de comprador y vendedor se muestra por separado.
- Spec ligera: el diseño, los contratos y las pruebas exactas se fijan al iniciar la HU (`plan.md`).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador (spec ligera)
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026
- **Detalle:** generada desde Jira, la maqueta y el modelo de datos para tener todo el backlog especificado (SCRUM-86, pedido del docente). Al iniciar la HU se completan `plan.md` y `task.md` y se resuelven las decisiones pendientes.
