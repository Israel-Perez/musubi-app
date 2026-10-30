# HU-39 — Revisar reportes y moderar contenido (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-39 / SCRUM-62 / Sprint 5 (23 nov – 4 dic 2026) / M-14 / [musubi-api:HU-39](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m14-admin/HU-39-moderar-contenido)

## Contexto
Jira (SCRUM-62): Como **administrador**, quiero **revisar los reportes**, para **retirar contenido falso o inapropiado**.

- Maqueta: sin pantalla propia. Se diseña con la guía de estilo de la maqueta; el lineamiento 4 permite agregar, nunca quitar.
- Trazabilidad: RF-54 · CU-24 · RNF-03, RNF-04.
- Origen: Propuesta inicial §11.

**Depende de:** `02-01`, `02-03`, `02-04` (piezas de la maqueta), `HU-28`, `02-07`.

## Requisitos
1. El administrador ve los reportes con su motivo y el elemento reportado.
2. Puede retirar el contenido reportado o descartar el reporte.
3. Solo el administrador puede moderar contenido (RNF-03) y sus acciones quedan registradas (RNF-04).

RNF que aplican: RNF-03, RNF-04.

## Diseño
- Feature `lib/features/admin/` con `domain/`, `data/` y `presentation/` (skill `vertical-slice`).
- Pantallas con las piezas de `lib/core/widgets/` y los tokens de 02-04, iguales a la maqueta.
- Consume las filas del back de HU-39. Mientras no existan: repositorio fake con `NOTE (musubi-api:HU-39)` (skill `deferred-scope-fakes`).

## Contratos
Filas de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) para HU-39, enlazadas desde `lib/core/network/api_paths.dart` (skill `api-contract`). Se listan al detallar.

## Tests
- `test/features//`: repositorio HTTP con `FakeHttpAdapter` (mapeo y errores en español).
- Widget tests por estado (carga, vacío, error y éxito) y por cada criterio de aceptación.
- Widget tests de las pantallas nuevas (sin escena de maqueta).

## Criterios
- [ ] El administrador ve los reportes con su motivo y el elemento reportado.
- [ ] Puede retirar el contenido reportado o descartar el reporte.
- [ ] Solo el administrador puede moderar contenido (RNF-03) y sus acciones quedan registradas (RNF-04).
- [ ] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS.

## Límites
- Spec ligera: el diseño, los contratos y las pruebas exactas se fijan al iniciar la HU (`plan.md`).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador (spec ligera)
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026
- **Detalle:** generada desde Jira, la maqueta y el modelo de datos para tener todo el backlog especificado (SCRUM-86, pedido del docente). Al iniciar la HU se completan `plan.md` y `task.md` y se resuelven las decisiones pendientes.
