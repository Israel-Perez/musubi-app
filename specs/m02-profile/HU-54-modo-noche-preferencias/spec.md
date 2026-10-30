# HU-54 — Elegir modo noche y preferencias (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-54 / SCRUM-71 / por asignar / M-02 / [musubi-api:HU-54](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m02-profile/HU-54-modo-noche-preferencias)

## Contexto
Jira (SCRUM-71): Como **usuario**, quiero **cambiar entre modo claro y modo noche y ajustar mis preferencias**, para **usar la app con comodidad a cualquier hora**.

- Maqueta: `Ajustes`.
- Trazabilidad: sin RF/RNF en Jira (historia que nació de la maqueta, SCRUM-75).
- Origen: maqueta (sección 10, G-07).

**Depende de:** `02-01`, `02-03`, `02-04` (piezas de la maqueta), `HU-04`.

## Requisitos
1. Ajustes ofrece el modo claro, el modo noche y "como el sistema".
2. El modo noche usa la paleta oscura de la guía de estilo y mantiene el contraste AA (RNF-20).
3. La preferencia se conserva al cerrar y abrir la app.

RNF que aplican: RNF-20.

## Diseño
- Feature `lib/features/profile/` con `domain/`, `data/` y `presentation/` (skill `vertical-slice`).
- Pantallas con las piezas de `lib/core/widgets/` y los tokens de 02-04, iguales a la maqueta.
- Consume las filas del back de HU-54. Mientras no existan: repositorio fake con `NOTE (musubi-api:HU-54)` (skill `deferred-scope-fakes`).

## Contratos
Filas de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) para HU-54, enlazadas desde `lib/core/network/api_paths.dart` (skill `api-contract`). Se listan al detallar.

## Tests
- `test/features//`: repositorio HTTP con `FakeHttpAdapter` (mapeo y errores en español).
- Widget tests por estado (carga, vacío, error y éxito) y por cada criterio de aceptación.
- `tool/screenshots_test.dart`: escenas de las pantallas, comparadas con la maqueta en claro y oscuro.

## Criterios
- [ ] Ajustes ofrece el modo claro, el modo noche y "como el sistema".
- [ ] El modo noche usa la paleta oscura de la guía de estilo y mantiene el contraste AA (RNF-20).
- [ ] La preferencia se conserva al cerrar y abrir la app.
- [ ] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS.

## Límites
- Decisión pendiente (Jira): qué otras preferencias de la pantalla Ajustes entran al MVP (notificaciones por tipo).
- Spec ligera: el diseño, los contratos y las pruebas exactas se fijan al iniciar la HU (`plan.md`).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador (spec ligera)
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026
- **Detalle:** generada desde Jira, la maqueta y el modelo de datos para tener todo el backlog especificado (SCRUM-86, pedido del docente). Al iniciar la HU se completan `plan.md` y `task.md` y se resuelven las decisiones pendientes.
