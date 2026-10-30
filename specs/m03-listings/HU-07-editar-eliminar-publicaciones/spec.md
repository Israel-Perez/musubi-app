# HU-07 — Editar o eliminar mis publicaciones (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-07 / SCRUM-24 / Sprint 2 (12 – 23 oct 2026) / M-03 / [musubi-api:HU-07](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m03-listings/HU-07-editar-eliminar-publicaciones)

## Contexto
Jira (SCRUM-24): Como **vendedor**, quiero **editar o eliminar mis publicaciones**, para **que la información siempre sea correcta**.

- Maqueta: `Perfil`, `Mis-productos`.
- Trazabilidad: RF-08, RF-09 · CU-05 · RN-07 · RNF-03.
- Origen: Propuesta inicial §11.

**Depende de:** `02-01`, `02-03`, `02-04` (piezas de la maqueta), `HU-06`.

## Requisitos
1. Solo el dueño de la publicación puede editarla o eliminarla (RNF-03).
2. Si cambian el nombre, la categoría, el precio o la descripción, el sistema vuelve a buscar coincidencias (RF-08).
3. Una publicación con pedidos **Pendientes** o **Confirmados** no puede eliminarse hasta que se completen o cancelen (RN-07).

RNF que aplican: RNF-03.

## Diseño
- Feature `lib/features/listings/` con `domain/`, `data/` y `presentation/` (skill `vertical-slice`).
- Pantallas con las piezas de `lib/core/widgets/` y los tokens de 02-04, iguales a la maqueta.
- Consume las filas del back de HU-07. Mientras no existan: repositorio fake con `NOTE (musubi-api:HU-07)` (skill `deferred-scope-fakes`).

## Contratos
Filas de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) para HU-07, enlazadas desde `lib/core/network/api_paths.dart` (skill `api-contract`). Se listan al detallar.

## Tests
- `test/features//`: repositorio HTTP con `FakeHttpAdapter` (mapeo y errores en español).
- Widget tests por estado (carga, vacío, error y éxito) y por cada criterio de aceptación.
- `tool/screenshots_test.dart`: escenas de las pantallas, comparadas con la maqueta en claro y oscuro.

## Criterios
- [ ] Solo el dueño de la publicación puede editarla o eliminarla (RNF-03).
- [ ] Si cambian el nombre, la categoría, el precio o la descripción, el sistema vuelve a buscar coincidencias (RF-08).
- [ ] Una publicación con pedidos **Pendientes** o **Confirmados** no puede eliminarse hasta que se completen o cancelen (RN-07).
- [ ] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS.

## Límites
- Spec ligera: el diseño, los contratos y las pruebas exactas se fijan al iniciar la HU (`plan.md`).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador (spec ligera)
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026
- **Detalle:** generada desde Jira, la maqueta y el modelo de datos para tener todo el backlog especificado (SCRUM-86, pedido del docente). Al iniciar la HU se completan `plan.md` y `task.md` y se resuelven las decisiones pendientes.
