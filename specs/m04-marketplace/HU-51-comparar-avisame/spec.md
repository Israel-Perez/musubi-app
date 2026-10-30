# HU-51 — Comparar opciones y pedir aviso de disponibilidad (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-51 / SCRUM-70 / por asignar / M-04 / [musubi-api:HU-51](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m04-marketplace/HU-51-comparar-avisame)

## Contexto
Jira (SCRUM-70): Como **comprador**, quiero **comparar un producto con publicaciones similares y pedir un aviso cuando vuelva a estar disponible**, para **elegir la mejor opción y no perder un producto agotado**.

- Maqueta: `Producto`.
- Trazabilidad: sin RF/RNF en Jira (historia que nació de la maqueta, SCRUM-75).
- Origen: maqueta (sección 3, G-04).

**Depende de:** `02-01`, `02-03`, `02-04` (piezas de la maqueta), `HU-11`, `HU-29`.

## Requisitos
1. El detalle muestra publicaciones similares comparadas por reputación del vendedor, ventas y precio.
2. En un producto agotado, el botón "Avísame" registra el interés.
3. Cuando el producto vuelve a tener existencias, llega una notificación push (relación con HU-29 y HU-31).

RNF que aplican: se confirman al detallar.

## Diseño
- Feature `lib/features/marketplace/` con `domain/`, `data/` y `presentation/` (skill `vertical-slice`).
- Pantallas con las piezas de `lib/core/widgets/` y los tokens de 02-04, iguales a la maqueta.
- Consume las filas del back de HU-51. Mientras no existan: repositorio fake con `NOTE (musubi-api:HU-51)` (skill `deferred-scope-fakes`).

## Contratos
Filas de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) para HU-51, enlazadas desde `lib/core/network/api_paths.dart` (skill `api-contract`). Se listan al detallar.

## Tests
- `test/features//`: repositorio HTTP con `FakeHttpAdapter` (mapeo y errores en español).
- Widget tests por estado (carga, vacío, error y éxito) y por cada criterio de aceptación.
- `tool/screenshots_test.dart`: escenas de las pantallas, comparadas con la maqueta en claro y oscuro.

## Criterios
- [ ] El detalle muestra publicaciones similares comparadas por reputación del vendedor, ventas y precio.
- [ ] En un producto agotado, el botón "Avísame" registra el interés.
- [ ] Cuando el producto vuelve a tener existencias, llega una notificación push (relación con HU-29 y HU-31).
- [ ] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS.

## Límites
- Decisión pendiente (Jira): el criterio de "similar" (misma categoría y palabras clave) y si se apoya en el modelo de ML de HU-35.
- Spec ligera: el diseño, los contratos y las pruebas exactas se fijan al iniciar la HU (`plan.md`).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador (spec ligera)
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026
- **Detalle:** generada desde Jira, la maqueta y el modelo de datos para tener todo el backlog especificado (SCRUM-86, pedido del docente). Al iniciar la HU se completan `plan.md` y `task.md` y se resuelven las decisiones pendientes.
