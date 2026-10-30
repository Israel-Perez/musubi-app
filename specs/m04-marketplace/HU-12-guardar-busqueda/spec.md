# HU-12 — Guardar una búsqueda sin resultados (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-12 / SCRUM-51 / Sprint 4 (9 – 20 nov 2026) / M-04 / [musubi-api:HU-12](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m04-marketplace/HU-12-guardar-busqueda)

## Contexto
Jira (SCRUM-51): Como **comprador**, quiero **que se conserve una búsqueda que no tuvo resultados**, para **recibir un aviso cuando aparezca un producto compatible**.

- Maqueta: `Busqueda`, `Busqueda-filtros`, `Busqueda-vacia`.
- Trazabilidad: RF-15, RF-23, RF-38 · CU-07 · Flujo D · RN-34 · RNF-07.
- Origen: Propuesta inicial §11.

**Depende de:** `02-01`, `02-03`, `02-04` (piezas de la maqueta), `HU-09`, `HU-29`.

## Requisitos
1. Cuando una búsqueda no tiene resultados, el sistema ofrece **guardar la búsqueda** (interés privado) o **convertirla en solicitud** (necesidad pública).
2. El usuario puede consultar y eliminar sus búsquedas guardadas.
3. Cuando se publica un producto compatible, el usuario recibe: "El producto que buscaste anteriormente ya está disponible."
4. Las búsquedas guardadas son privadas (RNF-07) y expiran después de [POR DEFINIR] días (RN-34).

RNF que aplican: RNF-07.

## Diseño
- Feature `lib/features/marketplace/` con `domain/`, `data/` y `presentation/` (skill `vertical-slice`).
- Pantallas con las piezas de `lib/core/widgets/` y los tokens de 02-04, iguales a la maqueta.
- Consume las filas del back de HU-12. Mientras no existan: repositorio fake con `NOTE (musubi-api:HU-12)` (skill `deferred-scope-fakes`).

## Contratos
Filas de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) para HU-12, enlazadas desde `lib/core/network/api_paths.dart` (skill `api-contract`). Se listan al detallar.

## Tests
- `test/features//`: repositorio HTTP con `FakeHttpAdapter` (mapeo y errores en español).
- Widget tests por estado (carga, vacío, error y éxito) y por cada criterio de aceptación.
- `tool/screenshots_test.dart`: escenas de las pantallas, comparadas con la maqueta en claro y oscuro.

## Criterios
- [ ] Cuando una búsqueda no tiene resultados, el sistema ofrece **guardar la búsqueda** (interés privado) o **convertirla en solicitud** (necesidad pública).
- [ ] El usuario puede consultar y eliminar sus búsquedas guardadas.
- [ ] Cuando se publica un producto compatible, el usuario recibe: "El producto que buscaste anteriormente ya está disponible."
- [ ] Las búsquedas guardadas son privadas (RNF-07) y expiran después de [POR DEFINIR] días (RN-34).
- [ ] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS.

## Límites
- Spec ligera: el diseño, los contratos y las pruebas exactas se fijan al iniciar la HU (`plan.md`).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador (spec ligera)
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026
- **Detalle:** generada desde Jira, la maqueta y el modelo de datos para tener todo el backlog especificado (SCRUM-86, pedido del docente). Al iniciar la HU se completan `plan.md` y `task.md` y se resuelven las decisiones pendientes.
