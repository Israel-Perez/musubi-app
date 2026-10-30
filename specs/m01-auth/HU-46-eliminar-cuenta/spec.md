# HU-46 — Eliminar mi cuenta y mis datos (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-46 / SCRUM-32 / Sprint 2 (12 – 23 oct 2026) / M-01 / [musubi-api:HU-46](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m01-auth/HU-46-eliminar-cuenta)

## Contexto
Jira (SCRUM-32): Como **usuario**, quiero **eliminar mi cuenta y mis datos desde la aplicación o desde una página web**, para **tener control sobre mi información personal**.

- Maqueta: `Privacidad`, `Aviso-privacidad`.
- Trazabilidad: RNF-08 · Entregable 1 §12 (requisito de Google Play) · LFPDPPP 2025.
- Origen: Entregable 1 §12 — historia nueva, no estaba en la lista original.

**Depende de:** `02-01`, `02-03`, `02-04` (piezas de la maqueta), `HU-01`, `HU-04`.

## Requisitos
1. Existe la opción "Eliminar cuenta" dentro de la aplicación.
2. Existe una página web pública, en el dominio del proyecto, para solicitar la eliminación de la cuenta.
3. Se informa al usuario qué datos se eliminan y cuáles se conservan, y por cuánto tiempo.
4. El procedimiento es congruente con el aviso de privacidad.

RNF que aplican: RNF-08.

## Diseño
- Feature `lib/features/auth/` con `domain/`, `data/` y `presentation/` (skill `vertical-slice`).
- Pantallas con las piezas de `lib/core/widgets/` y los tokens de 02-04, iguales a la maqueta.
- Consume las filas del back de HU-46. Mientras no existan: repositorio fake con `NOTE (musubi-api:HU-46)` (skill `deferred-scope-fakes`).

## Contratos
Filas de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) para HU-46, enlazadas desde `lib/core/network/api_paths.dart` (skill `api-contract`). Se listan al detallar.

## Tests
- `test/features//`: repositorio HTTP con `FakeHttpAdapter` (mapeo y errores en español).
- Widget tests por estado (carga, vacío, error y éxito) y por cada criterio de aceptación.
- `tool/screenshots_test.dart`: escenas de las pantallas, comparadas con la maqueta en claro y oscuro.

## Criterios
- [ ] Existe la opción "Eliminar cuenta" dentro de la aplicación.
- [ ] Existe una página web pública, en el dominio del proyecto, para solicitar la eliminación de la cuenta.
- [ ] Se informa al usuario qué datos se eliminan y cuáles se conservan, y por cuánto tiempo.
- [ ] El procedimiento es congruente con el aviso de privacidad.
- [ ] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS.

## Límites
- Decisión pendiente (Jira): Debe estar lista antes de la prueba cerrada en Google Play (inicio 9 nov 2026).
- Spec ligera: el diseño, los contratos y las pruebas exactas se fijan al iniciar la HU (`plan.md`).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador (spec ligera)
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026
- **Detalle:** generada desde Jira, la maqueta y el modelo de datos para tener todo el backlog especificado (SCRUM-86, pedido del docente). Al iniciar la HU se completan `plan.md` y `task.md` y se resuelven las decisiones pendientes.
