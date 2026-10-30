# HU-09 — Buscar productos por palabra clave (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-09 / SCRUM-26 / Sprint 2 (12 – 23 oct 2026) / M-04 / [musubi-api:HU-09](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m04-marketplace/HU-09-buscar-productos)

## Contexto
Jira (SCRUM-26): Como **comprador**, quiero **buscar productos por nombre o palabra clave**, para **encontrar rápido lo que necesito**.

- Maqueta: `Inicio-visitante`, `Se-busca-visitante`, `Producto-visitante`, `Visitante-modal`, `Busqueda`, `Busqueda-filtros`, `Busqueda-vacia`.
- Trazabilidad: RF-12 · CU-06 · RNF-09.
- Origen: Propuesta inicial §11.

**Depende de:** `02-01`, `02-03`, `02-04` (piezas de la maqueta), `HU-06`.

## Requisitos
1. La búsqueda por nombre o palabras clave devuelve solo productos **Disponibles**.
2. Los resultados cargan en un tiempo aceptable para el usuario (RNF-09; métrica [POR DEFINIR]).
3. Si la búsqueda no tiene resultados, se ofrecen las opciones de HU-12 (guardar búsqueda o convertirla en solicitud).

RNF que aplican: RNF-09.

## Diseño
- Feature `lib/features/marketplace/` con `domain/`, `data/` y `presentation/` (skill `vertical-slice`).
- Pantallas con las piezas de `lib/core/widgets/` y los tokens de 02-04, iguales a la maqueta.
- Consume las filas del back de HU-09. Mientras no existan: repositorio fake con `NOTE (musubi-api:HU-09)` (skill `deferred-scope-fakes`).

## Contratos
Filas de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) para HU-09, enlazadas desde `lib/core/network/api_paths.dart` (skill `api-contract`). Se listan al detallar.

## Tests
- `test/features//`: repositorio HTTP con `FakeHttpAdapter` (mapeo y errores en español).
- Widget tests por estado (carga, vacío, error y éxito) y por cada criterio de aceptación.
- `tool/screenshots_test.dart`: escenas de las pantallas, comparadas con la maqueta en claro y oscuro.

## Criterios
- [ ] La búsqueda por nombre o palabras clave devuelve solo productos **Disponibles**.
- [ ] Los resultados cargan en un tiempo aceptable para el usuario (RNF-09; métrica [POR DEFINIR]).
- [ ] Si la búsqueda no tiene resultados, se ofrecen las opciones de HU-12 (guardar búsqueda o convertirla en solicitud).
- [ ] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS.

## Límites
- Spec ligera: el diseño, los contratos y las pruebas exactas se fijan al iniciar la HU (`plan.md`).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador (spec ligera)
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026
- **Detalle:** generada desde Jira, la maqueta y el modelo de datos para tener todo el backlog especificado (SCRUM-86, pedido del docente). Al iniciar la HU se completan `plan.md` y `task.md` y se resuelven las decisiones pendientes.
