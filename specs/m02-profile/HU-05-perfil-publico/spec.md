# HU-05 — Consultar perfil y reputación de otro usuario (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-05 / SCRUM-34 / Sprint 3 (26 oct – 6 nov 2026) / M-02 / [musubi-api:HU-05](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m02-profile/HU-05-perfil-publico)

## Contexto
Jira (SCRUM-34): Como **usuario**, quiero **consultar el perfil y la reputación de otro usuario**, para **decidir si hago un trato con él**.

- Maqueta: `Producto`, `Perfil-vendedor`, `Chat-Valeria`.
- Trazabilidad: RF-05, RF-36 · CU-03 · RN-26.
- Origen: Propuesta inicial §11.

**Depende de:** `02-01`, `02-03`, `02-04` (piezas de la maqueta), `HU-04`, `HU-27`.

## Requisitos
1. El perfil público muestra nombre, reputación (promedio), número de calificaciones y publicaciones activas (RF-05).
2. Un usuario sin calificaciones se muestra como "Sin calificaciones" (RN-26).
3. El perfil del vendedor es accesible desde el detalle de una publicación (RF-14).

RNF que aplican: se confirman al detallar.

## Diseño
- Feature `lib/features/profile/` con `domain/`, `data/` y `presentation/` (skill `vertical-slice`).
- Pantallas con las piezas de `lib/core/widgets/` y los tokens de 02-04, iguales a la maqueta.
- Consume las filas del back de HU-05. Mientras no existan: repositorio fake con `NOTE (musubi-api:HU-05)` (skill `deferred-scope-fakes`).

## Contratos
Filas de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) para HU-05, enlazadas desde `lib/core/network/api_paths.dart` (skill `api-contract`). Se listan al detallar.

## Tests
- `test/features//`: repositorio HTTP con `FakeHttpAdapter` (mapeo y errores en español).
- Widget tests por estado (carga, vacío, error y éxito) y por cada criterio de aceptación.
- `tool/screenshots_test.dart`: escenas de las pantallas, comparadas con la maqueta en claro y oscuro.

## Criterios
- [ ] El perfil público muestra nombre, reputación (promedio), número de calificaciones y publicaciones activas (RF-05).
- [ ] Un usuario sin calificaciones se muestra como "Sin calificaciones" (RN-26).
- [ ] El perfil del vendedor es accesible desde el detalle de una publicación (RF-14).
- [ ] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS.

## Límites
- Decisión pendiente (Jira): Se ubica en Sprint 3 porque depende del sistema de reputación.
- Spec ligera: el diseño, los contratos y las pruebas exactas se fijan al iniciar la HU (`plan.md`).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador (spec ligera)
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026
- **Detalle:** generada desde Jira, la maqueta y el modelo de datos para tener todo el backlog especificado (SCRUM-86, pedido del docente). Al iniciar la HU se completan `plan.md` y `task.md` y se resuelven las decisiones pendientes.
