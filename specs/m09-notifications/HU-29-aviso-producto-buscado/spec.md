# HU-29 — Aviso de producto buscado disponible (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-29 / SCRUM-47 / Sprint 3 (26 oct – 6 nov 2026) / M-09 / [musubi-api:HU-29](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m09-notifications/HU-29-aviso-producto-buscado)

## Contexto
Jira (SCRUM-47): Como **comprador**, quiero **recibir una notificación cuando aparezca un producto que busqué o uno similar**, para **no revisar la aplicación constantemente**.

- Maqueta: `Notificaciones`.
- Trazabilidad: RF-38 · CU-14 · RN-28 a RN-31.
- Origen: Propuesta inicial §11.

**Depende de:** `02-01`, `02-03`, `02-04` (piezas de la maqueta), `HU-12`, `HU-31`.

## Requisitos
1. Se envía una notificación push cuando se publica un producto que coincide o es similar a una solicitud activa o a una búsqueda guardada.
2. Al tocar la notificación se abre el producto.
3. Se respetan el umbral de relevancia, la no repetición y el límite diario (RN-28 a RN-30).

RNF que aplican: se confirman al detallar.

## Diseño
- Feature `lib/features/notifications/` con `domain/`, `data/` y `presentation/` (skill `vertical-slice`).
- Pantallas con las piezas de `lib/core/widgets/` y los tokens de 02-04, iguales a la maqueta.
- Consume las filas del back de HU-29. Mientras no existan: repositorio fake con `NOTE (musubi-api:HU-29)` (skill `deferred-scope-fakes`).
- Avisos push con FCM (HU-31) y su permiso pedido en contexto (L-16f).

## Contratos
Filas de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) para HU-29, enlazadas desde `lib/core/network/api_paths.dart` (skill `api-contract`). Se listan al detallar.

## Tests
- `test/features//`: repositorio HTTP con `FakeHttpAdapter` (mapeo y errores en español).
- Widget tests por estado (carga, vacío, error y éxito) y por cada criterio de aceptación.
- `tool/screenshots_test.dart`: escenas de las pantallas, comparadas con la maqueta en claro y oscuro.

## Criterios
- [ ] Se envía una notificación push cuando se publica un producto que coincide o es similar a una solicitud activa o a una búsqueda guardada.
- [ ] Al tocar la notificación se abre el producto.
- [ ] Se respetan el umbral de relevancia, la no repetición y el límite diario (RN-28 a RN-30).
- [ ] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS.

## Límites
- Decisión pendiente (Jira): En Sprint 3 aplica a solicitudes activas; las búsquedas guardadas se agregan en Sprint 4 (HU-12).
- Spec ligera: el diseño, los contratos y las pruebas exactas se fijan al iniciar la HU (`plan.md`).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador (spec ligera)
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026
- **Detalle:** generada desde Jira, la maqueta y el modelo de datos para tener todo el backlog especificado (SCRUM-86, pedido del docente). Al iniciar la HU se completan `plan.md` y `task.md` y se resuelven las decisiones pendientes.
