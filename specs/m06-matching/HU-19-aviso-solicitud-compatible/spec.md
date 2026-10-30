# HU-19 — Aviso al vendedor de solicitud compatible (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-19 / SCRUM-41 / Sprint 3 (26 oct – 6 nov 2026) / M-06 / [musubi-api:HU-19](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m06-matching/HU-19-aviso-solicitud-compatible)

## Contexto
Jira (SCRUM-41): Como **vendedor**, quiero **que el sistema me avise cuando una solicitud sea compatible con alguno de mis productos**, para **ofrecerlo a tiempo**.

- Maqueta: sin pantalla propia. Se diseña con la guía de estilo de la maqueta; el lineamiento 4 permite agregar, nunca quitar.
- Trazabilidad: RF-23, RF-39 · CU-13, CU-14 · RN-28 a RN-31.
- Origen: Propuesta inicial §11.

**Depende de:** `02-01`, `02-03`, `02-04` (piezas de la maqueta), `HU-18`, `HU-31`.

## Requisitos
1. Cuando se publica una solicitud compatible con un producto **Disponible**, el vendedor recibe una notificación (RF-39).
2. Solo se notifican coincidencias que superen el umbral de relevancia (RN-28).
3. Una misma coincidencia no se notifica más de una vez (RN-29) y se respeta el límite diario (RN-30).
4. No se notifican coincidencias sobre publicaciones o solicitudes propias (RN-31).
5. Desde la notificación el vendedor abre la solicitud y puede responder "Yo tengo este producto".

RNF que aplican: se confirman al detallar.

## Diseño
- Feature `lib/features/matching/` con `domain/`, `data/` y `presentation/` (skill `vertical-slice`).
- Pantallas con las piezas de `lib/core/widgets/` y los tokens de 02-04, iguales a la maqueta.
- Consume las filas del back de HU-19. Mientras no existan: repositorio fake con `NOTE (musubi-api:HU-19)` (skill `deferred-scope-fakes`).
- Avisos push con FCM (HU-31) y su permiso pedido en contexto (L-16f).

## Contratos
Filas de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) para HU-19, enlazadas desde `lib/core/network/api_paths.dart` (skill `api-contract`). Se listan al detallar.

## Tests
- `test/features//`: repositorio HTTP con `FakeHttpAdapter` (mapeo y errores en español).
- Widget tests por estado (carga, vacío, error y éxito) y por cada criterio de aceptación.
- Widget tests de las pantallas nuevas (sin escena de maqueta).

## Criterios
- [ ] Cuando se publica una solicitud compatible con un producto **Disponible**, el vendedor recibe una notificación (RF-39).
- [ ] Solo se notifican coincidencias que superen el umbral de relevancia (RN-28).
- [ ] Una misma coincidencia no se notifica más de una vez (RN-29) y se respeta el límite diario (RN-30).
- [ ] No se notifican coincidencias sobre publicaciones o solicitudes propias (RN-31).
- [ ] Desde la notificación el vendedor abre la solicitud y puede responder "Yo tengo este producto".
- [ ] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS.

## Límites
- Spec ligera: el diseño, los contratos y las pruebas exactas se fijan al iniciar la HU (`plan.md`).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador (spec ligera)
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026
- **Detalle:** generada desde Jira, la maqueta y el modelo de datos para tener todo el backlog especificado (SCRUM-86, pedido del docente). Al iniciar la HU se completan `plan.md` y `task.md` y se resuelven las decisiones pendientes.
