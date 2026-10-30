# HU-41 — Gestionar categorías (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-41 / SCRUM-64 / Sprint 5 (23 nov – 4 dic 2026) / M-14 / [musubi-api:HU-41](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m14-admin/HU-41-gestionar-categorias)

## Contexto
Jira (SCRUM-64): Como **administrador**, quiero **gestionar las categorías**, para **mantener organizada la plataforma**.

- Maqueta: sin pantalla propia. Se diseña con la guía de estilo de la maqueta; el lineamiento 4 permite agregar, nunca quitar.
- Trazabilidad: RF-56 · CU-26.
- Origen: Propuesta inicial §11.

**Depende de:** `02-01`, `02-03`, `02-04` (piezas de la maqueta), `HU-06`.

## Requisitos
1. El administrador puede crear, editar y desactivar categorías.
2. Las categorías activas son las que aparecen al publicar productos y solicitudes, y en los filtros.

RNF que aplican: se confirman al detallar.

## Diseño
- Feature `lib/features/admin/` con `domain/`, `data/` y `presentation/` (skill `vertical-slice`).
- Pantallas con las piezas de `lib/core/widgets/` y los tokens de 02-04, iguales a la maqueta.
- Consume las filas del back de HU-41. Mientras no existan: repositorio fake con `NOTE (musubi-api:HU-41)` (skill `deferred-scope-fakes`).

## Contratos
Filas de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) para HU-41, enlazadas desde `lib/core/network/api_paths.dart` (skill `api-contract`). Se listan al detallar.

## Tests
- `test/features//`: repositorio HTTP con `FakeHttpAdapter` (mapeo y errores en español).
- Widget tests por estado (carga, vacío, error y éxito) y por cada criterio de aceptación.
- Widget tests de las pantallas nuevas (sin escena de maqueta).

## Criterios
- [ ] El administrador puede crear, editar y desactivar categorías.
- [ ] Las categorías activas son las que aparecen al publicar productos y solicitudes, y en los filtros.
- [ ] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS.

## Límites
- Decisión pendiente (Jira): Desde Sprint 2 se requiere un catálogo inicial de categorías cargado en la base de datos.
- Spec ligera: el diseño, los contratos y las pruebas exactas se fijan al iniciar la HU (`plan.md`).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador (spec ligera)
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026
- **Detalle:** generada desde Jira, la maqueta y el modelo de datos para tener todo el backlog especificado (SCRUM-86, pedido del docente). Al iniciar la HU se completan `plan.md` y `task.md` y se resuelven las decisiones pendientes.
