# HU-50 — Manejar la cantidad disponible de un producto (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-50 / SCRUM-67 / por asignar / M-03 / [musubi-api:HU-50](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m03-listings/HU-50-cantidad-disponible)

## Contexto
Jira (SCRUM-67): Como **vendedor**, quiero **indicar cuántas piezas tengo de un producto**, para **vender varias unidades con una sola publicación y que los compradores sepan cuántas quedan**.

- Maqueta: `Vender-4`, `Producto`, `Mis-productos`.
- Trazabilidad: sin RF/RNF en Jira (historia que nació de la maqueta, SCRUM-75).
- Origen: maqueta (secciones 3, 5 y 10; G-03).

**Depende de:** `02-01`, `02-03`, `02-04` (piezas de la maqueta), `HU-06`, `HU-23`.

## Requisitos
1. Al publicar se captura la cantidad disponible (paso "Estado y cantidad").
2. El detalle muestra "Quedan N", "Último" o "Agotado" según el inventario.
3. Un apartado o una venta descuenta la cantidad de forma atómica, sin vender de más.
4. El buscador permite ocultar los agotados.

RNF que aplican: se confirman al detallar.

## Diseño
- Feature `lib/features/listings/` con `domain/`, `data/` y `presentation/` (skill `vertical-slice`).
- Pantallas con las piezas de `lib/core/widgets/` y los tokens de 02-04, iguales a la maqueta.
- Consume las filas del back de HU-50. Mientras no existan: repositorio fake con `NOTE (musubi-api:HU-50)` (skill `deferred-scope-fakes`).

## Contratos
Filas de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) para HU-50, enlazadas desde `lib/core/network/api_paths.dart` (skill `api-contract`). Se listan al detallar.

## Tests
- `test/features//`: repositorio HTTP con `FakeHttpAdapter` (mapeo y errores en español).
- Widget tests por estado (carga, vacío, error y éxito) y por cada criterio de aceptación.
- `tool/screenshots_test.dart`: escenas de las pantallas, comparadas con la maqueta en claro y oscuro.

## Criterios
- [ ] Al publicar se captura la cantidad disponible (paso "Estado y cantidad").
- [ ] El detalle muestra "Quedan N", "Último" o "Agotado" según el inventario.
- [ ] Un apartado o una venta descuenta la cantidad de forma atómica, sin vender de más.
- [ ] El buscador permite ocultar los agotados.
- [ ] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS.

## Límites
- Decisión pendiente (Jira): si un apartado vencido regresa la unidad al inventario de forma automática (relación con HU-53).
- Spec ligera: el diseño, los contratos y las pruebas exactas se fijan al iniciar la HU (`plan.md`).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador (spec ligera)
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026
- **Detalle:** generada desde Jira, la maqueta y el modelo de datos para tener todo el backlog especificado (SCRUM-86, pedido del docente). Al iniciar la HU se completan `plan.md` y `task.md` y se resuelven las decisiones pendientes.
