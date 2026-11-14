# HU-19 — Aviso al vendedor de solicitud compatible (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-19 / SCRUM-41 / Sprint 4 (9 – 20 nov 2026) / M-06 / [musubi-api:HU-19](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m06-matching/HU-19-aviso-solicitud-compatible)

## Contexto
Jira (SCRUM-41): Como **vendedor**, quiero **que el sistema me avise cuando una solicitud sea compatible con alguno de mis productos**, para **ofrecerlo a tiempo**.

- Maqueta: `Notificaciones` → "Coincidencias": "Hay una solicitud compatible con tu producto · Fernanda busca una bata de laboratorio talla M. Tu publicación coincide.", con el megáfono de "Se busca".
- Trazabilidad: RF-23, RF-39 · CU-13, CU-14 · RN-28 a RN-31.
- Las reglas (compatible, una vez, 3 al día, nunca lo propio) viven en la API; decisiones de la usuaria del 13-Nov-2026 en [musubi-api:HU-19](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m06-matching/HU-19-aviso-solicitud-compatible).

**Depende de:** `HU-16` ("Yo tengo este producto") y `HU-31` (avisos).

## Requisitos
1. **R1 · Aviso:** `wanted_match` sale en "Coincidencias" con el ícono de la maqueta.
2. **R2 · Abrir:** al tocarlo (o el push), se abre el tablero con "Yo tengo este producto" de esa solicitud (`target.type: wanted_board`).
3. **R3 · Ya no activa:** si la solicitud se cerró o venció, se queda en el tablero con "Esta solicitud ya no está activa.".

## Diseño
- `NotificationTarget.wantedBoard` y `routeFor` → `AppRoutes.wantedOffer(id)` (`/se-busca?ofrecer=`).
- `WantedBoardScreen(offerTo:)` trae la solicitud con `WantedRepository.get` y abre `showOfferSheet`.

## Contratos
Filas `GET /api/v1/notifications` (destino `wanted_board`) y `GET /api/v1/wanted/{id}` de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md), enlazadas desde `ApiPaths`.

## Tests
- `test/features/notifications/notification_flow_test.dart`: el aviso abre "Yo tengo este producto" y, si ya no está activa, lo dice.
- `test/features/notifications/notification_data_test.dart`: `wanted_board` y su ruta.
- Capturas `notificaciones` y `notificaciones-coincidencias`.

## Criterios
- [x] Desde la notificación el vendedor abre la solicitud y puede responder "Yo tengo este producto" → `notification_flow_test.dart`.
- [x] El resto de los criterios (umbral, no repetir, límite diario, nunca lo propio) → `musubi-api:HU-19`.
- [x] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` 652 al 100 % · critic PASS.

## Límites
- Las pruebas en el celular necesitan la API `0.5.0-alpha.27` desplegada.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026 (borrador ligero) · 13-Nov-2026 (detallado e implementado)
- **Detalle:** con las decisiones de la usuaria del 13-Nov-2026.
