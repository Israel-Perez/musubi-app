# HU-29 — Aviso de producto buscado disponible (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-29 / SCRUM-47 / Sprint 5 (14 nov – 1 dic 2026) / M-09 / [musubi-api:HU-29](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m09-notifications/HU-29-aviso-producto-buscado)

## Contexto
Jira (SCRUM-47): Como **comprador**, quiero **recibir una notificación cuando aparezca un producto que busqué o uno similar**, para **no revisar la aplicación constantemente**.

- Maqueta: `Notificaciones` → "Coincidencias".
- El aviso lo genera la API (`product_match`); la app ya muestra los avisos y el push (HU-31).

**Depende de:** [musubi-api:HU-29](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m09-notifications/HU-29-aviso-producto-buscado), `HU-31`.

## Requisitos
1. **R1:** el aviso sale en "Coincidencias" con su ícono (lupa).
2. **R2:** al tocarlo (en la lista o desde el push) se abre la publicación (`target: product`).

## Diseño
- `NotificationTarget.product` y `routeFor` → `AppRoutes.product`.

## Contratos
Fila `GET /api/v1/notifications` (HU-31) de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md).

## Tests
- `test/features/notifications/notification_data_test.dart`: `product` se lee y abre la publicación.

## Criterios
- [x] Al tocar el aviso se abre el producto → `notification_data_test.dart`.
- [x] `flutter analyze` 0 · `flutter test` al 100 %.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026 (borrador ligero) · 14-Nov-2026 (detallado e implementado)
