# HU-53 — Guardar productos en favoritos (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-53 / SCRUM-68 / por asignar / M-04 / [musubi-api:HU-53](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m04-marketplace/HU-53-favoritos)

## Contexto
Jira (SCRUM-68): Como **comprador**, quiero **guardar productos en favoritos**, para **volver a encontrarlos rápido y decidir después**.

- Maqueta: `Favoritos`, `Producto`.
- Trazabilidad: sin RF/RNF en Jira (historia que nació de la maqueta, SCRUM-75).
- Origen: maqueta (sección 10, G-06).

**Depende de:** `02-01`, `02-03`, `02-04` (piezas de la maqueta), `HU-11`.

## Requisitos
1. Desde el detalle o un listado, el ícono de favorito agrega o quita el producto.
2. La pantalla "Favoritos" lista lo guardado e indica si un producto se agotó o se eliminó.
3. Los favoritos son privados: nadie más los ve (RNF-07).

RNF que aplican: RNF-07.

## Diseño
- Feature `lib/features/marketplace/` con `domain/`, `data/` y `presentation/` (skill `vertical-slice`).
- Pantallas con las piezas de `lib/core/widgets/` y los tokens de 02-04, iguales a la maqueta.
- Consume las filas del back de HU-53. Mientras no existan: repositorio fake con `NOTE (musubi-api:HU-53)` (skill `deferred-scope-fakes`).

## Contratos
Filas de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) para HU-53, enlazadas desde `lib/core/network/api_paths.dart` (skill `api-contract`). Se listan al detallar.

## Tests
- `test/features//`: repositorio HTTP con `FakeHttpAdapter` (mapeo y errores en español).
- Widget tests por estado (carga, vacío, error y éxito) y por cada criterio de aceptación.
- `tool/screenshots_test.dart`: escenas de las pantallas, comparadas con la maqueta en claro y oscuro.

## Criterios
- [ ] Desde el detalle o un listado, el ícono de favorito agrega o quita el producto.
- [ ] La pantalla "Favoritos" lista lo guardado e indica si un producto se agotó o se eliminó.
- [ ] Los favoritos son privados: nadie más los ve (RNF-07).
- [ ] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS.

## Límites
- Decisión pendiente (Jira): si los favoritos funcionan sin conexión (caché local de la app).
- Spec ligera: el diseño, los contratos y las pruebas exactas se fijan al iniciar la HU (`plan.md`).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador (spec ligera)
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026
- **Detalle:** generada desde Jira, la maqueta y el modelo de datos para tener todo el backlog especificado (SCRUM-86, pedido del docente). Al iniciar la HU se completan `plan.md` y `task.md` y se resuelven las decisiones pendientes.
