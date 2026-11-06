# HU-21 — Ver el contexto de la conversación (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-21 / SCRUM-30 / Sprint 2 (12 – 23 oct 2026) / M-07 / [musubi-api:HU-21](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m07-chat/HU-21-contexto-conversacion)

## Contexto
Jira (SCRUM-30): Como **usuario**, quiero **que la conversación muestre el producto o la solicitud de la que se está hablando**, para **no perder el contexto**.

- Maqueta: `Mensajes`, `Chat`, `Acuerdo-esperando`, `Acuerdo-confirmado`.
- Trazabilidad: RF-28 · CU-15.
- Origen: Propuesta inicial §11.

**Depende de:** `02-01`, `02-03`, `02-04` (piezas de la maqueta), `HU-20`.

## Requisitos
1. Cada conversación muestra el producto, la solicitud o la oferta que la originó.
2. Desde ese contexto se puede abrir el detalle del elemento.

RNF que aplican: se confirman al detallar.

## Diseño
- La tarjeta de la publicación en `Chat-Valeria` (HU-20): "PUBLICACIÓN DE VALERIA" (o "TU PUBLICACIÓN"), con nombre, precio y estado **actuales**. Si ya no se puede ver: "Esta publicación ya no está disponible".
- **"Ver" abre el detalle** (`/producto/:id`, HU-11).
- La bandeja muestra el contexto en cada fila ("Compra · …" / "Venta · …" con la foto, HU-22).

## Contratos
`GET /api/v1/conversations/{id}` (`context { type, id, title, priceCents, condition, conditionDetail, photo, available }`) y `GET /api/v1/products/{id}` (musubi-api `docs/endpoints.md`).

## Tests
- `test/features/chat/chat_flow_test.dart`:
  - la tarjeta "PUBLICACIÓN DE VALERIA" con su precio y estado;
  - "\"Ver\" abre el detalle de la publicacion (HU-21)".

## Criterios
- [x] Cada conversación muestra el producto que la originó → la tarjeta del chat y la fila de la bandeja (`chat_flow_test`). Solicitudes y ofertas: `NOTE (HU-16)`.
- [x] Desde ese contexto se puede abrir el detalle del elemento → "\"Ver\" abre el detalle de la publicacion (HU-21)".

## Límites
- Contexto de solicitudes y ofertas: `NOTE (HU-16)`.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 06-Nov-2026
- **Detalle:** 29-Oct-2026: spec ligera (SCRUM-86). 06-Nov-2026 (SCRUM-30): cerrada con el chat (HU-20) y el detalle (HU-11).
