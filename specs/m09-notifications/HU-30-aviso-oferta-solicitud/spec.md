# HU-30 — Aviso de oferta en mi solicitud (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-30 / SCRUM-48 / Sprint 4 (9 – 20 nov 2026) / M-09 / [musubi-api:HU-30](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m09-notifications/HU-30-aviso-oferta-solicitud)

## Contexto
Jira (SCRUM-48): Como **comprador**, quiero **recibir una notificación cuando alguien indique que tiene el producto que solicité**, para **responder rápido**.

- Maqueta: `Notificaciones`: "Alguien tiene lo que buscas · Diego respondió “Yo tengo este producto” a tu solicitud de Calculadora Casio · $500."
- Trazabilidad: RF-40 · CU-11, CU-14.
- Decisión de la usuaria (13-Nov-2026): quien tenía una oferta pendiente se entera cuando la solicitud se cierra o se cancela ("Esta solicitud ya no está activa").

**Depende de:** `HU-16`, `HU-17` y `HU-31`.

## Requisitos
1. **R1 · Abrir la oferta:** el aviso de una oferta (`target.type: wanted`) abre `Mis-solicitudes` con esa solicitud elegida, en su pestaña, con sus ofertas.
2. **R2 · Cierre:** `offer_closed` sale en "Solicitudes" con la X en gris y no abre nada.

## Diseño
- `routeFor` → `AppRoutes.myWantedRequest(id)` (`/mis-solicitudes?solicitud=`); `MyWantedScreen(initialId:)` la elige cuando carga la lista.

## Contratos
Fila `GET /api/v1/notifications` de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) (tipos `offer_received` y `offer_closed`, destinos `wanted` y `none`).

## Tests
- `test/features/notifications/notification_flow_test.dart`: la oferta abre esa solicitud; un aviso sin destino se queda en `Notificaciones`.
- `test/features/notifications/notification_data_test.dart`: la ruta con la solicitud.

## Criterios
- [x] Se notifica al comprador cada vez que alguien responde "Yo tengo este producto" → la API (`musubi-api:HU-30`) y la lista de avisos.
- [x] Al tocar la notificación se abre la oferta dentro de la solicitud → `notification_flow_test.dart`.
- [x] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` al 100 % · critic PASS.

## Límites
- La solicitud se elige, pero la pantalla no baja sola hasta la oferta: las ofertas están justo debajo de la solicitud.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026 (borrador ligero) · 13-Nov-2026 (detallado e implementado)
- **Detalle:** con la decisión de la usuaria del 13-Nov-2026.
