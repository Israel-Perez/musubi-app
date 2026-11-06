# HU-22 — Bandeja de conversaciones (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-22 / SCRUM-31 / Sprint 2 (12 – 23 oct 2026) / M-07 / [musubi-api:HU-22](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m07-chat/HU-22-bandeja-conversaciones)

## Contexto
Jira (SCRUM-31): Como **usuario**, quiero **ver la lista de mis conversaciones**, para **dar seguimiento a varios tratos a la vez**.

- Maqueta: `Mensajes`, `Chat`, `Acuerdo-esperando`, `Acuerdo-confirmado`.
- Trazabilidad: RF-29 · CU-15.
- Origen: Propuesta inicial §11.

**Depende de:** `02-01`, `02-03`, `02-04` (piezas de la maqueta), `HU-20`.

## Requisitos
1. Las conversaciones se ordenan por actividad reciente.
2. Se muestra un indicador de mensajes no leídos.
3. Cada conversación muestra al otro participante y el elemento de contexto.

RNF que aplican: se confirman al detallar.

## Diseño
- `InboxScreen` en la pestaña **Mensajes** (maqueta `Mensajes`):
  - título y buscar;
  - control Todos / Compras / Ventas;
  - filas con iniciales, nombre (con insignia si hay sin leer), hora ("8:31 p. m.", "Ayer", "lun", "28/10"), último mensaje con el contador rojo, "Compra · …" / "Venta · …" y la foto de la publicación.
- `inboxProvider` (por pestaña) se vuelve a pedir al llegar `messageCreated` por el hub (HU-20).
- El chat marca la conversación como leída al abrirla y con cada mensaje que llega con ella abierta.

## Contratos
Filas "M-07" de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md): `GET /conversations` y `POST /conversations/{id}/read`.

## Tests
`test/features/chat/chat_flow_test.dart` (grupo "Mensajes (HU-22)"):
- filas, no leídos y filtro Ventas;
- tocar una conversación la abre;
- vacío;
- se vuelve a pedir en tiempo real.

Captura `mensajes`.

## Criterios
- [x] Las conversaciones se ordenan por actividad reciente → la API las entrega en ese orden (`musubi-api:HU-22`) y la app las muestra igual.
- [x] Se muestra un indicador de mensajes no leídos → "lista las conversaciones con sus no leidos y filtra Ventas".
- [x] Cada conversación muestra al otro participante y el elemento de contexto → la misma prueba ("Venta · Calculadora Casio").
- [x] `flutter analyze` sin observaciones y `flutter test` 284/284.

## Límites
- Filas de solicitudes y ofertas ("Tu solicitud", "Tu oferta"): `NOTE (HU-16)`.
- Buscar en mensajes: fuera de alcance por ahora (avisa "llega muy pronto").

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 06-Nov-2026
- **Detalle:** 29-Oct-2026: spec ligera (SCRUM-86). 06-Nov-2026 (SCRUM-31): implementada contra `musubi-api` `0.5.0-alpha.2`.
