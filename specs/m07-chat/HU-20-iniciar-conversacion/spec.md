# HU-20 — Iniciar una conversación con el vendedor (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-20 / SCRUM-29 / Sprint 2 (12 – 23 oct 2026) / M-07 / [musubi-api:HU-20](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m07-chat/HU-20-iniciar-conversacion)

## Contexto
Jira (SCRUM-29): Como **comprador**, quiero **iniciar una conversación con el vendedor desde la publicación o desde la oferta**, para **resolver dudas y negociar**.

- Maqueta: `Producto`, `Perfil-vendedor`, `Chat-Valeria`, `Mensajes`, `Chat`, `Acuerdo-esperando`, `Acuerdo-confirmado`.
- Trazabilidad: RF-26, RF-27 · CU-15 · RN-21, RN-22, RN-23 · RNF-10.
- Origen: Propuesta inicial §11.

**Depende de:** `02-01`, `02-03`, `02-04` (piezas de la maqueta), `HU-11`.

## Requisitos
1. Se puede iniciar un chat desde una publicación, una solicitud o una oferta.
2. Cada conversación es entre dos usuarios y está asociada a una publicación, solicitud u oferta (RN-21).
3. Los mensajes de texto se entregan casi en tiempo real (RNF-10).
4. Solo los participantes pueden leer la conversación (RN-22).
5. Los mensajes pueden reportarse (RN-23).

RNF que aplican: RNF-10.

## Diseño
- Feature `lib/features/chat/` con `domain/`, `data/` y `presentation/`. Detalle en [`plan.md`](plan.md).
- **Pantalla `Chat-Valeria`** (`ChatScreen`):
  - encabezado con la otra persona (iniciales e insignia de verificada);
  - tarjeta de la publicación con precio y estado actuales, y "Resumir acuerdo" con su halo (`glow`, 3 ciclos);
  - aviso de inicio, burbujas (las mías a la derecha en rojo) y la hora al final de cada intercambio;
  - caja "Escribe un mensaje…" y "Enviar".
- **Entrada:** con sesión, tocar un producto en Inicio abre el chat con quien lo vende. `POST /conversations` es idempotente: si ya existía, trae el historial.
  - `NOTE (HU-11)`: el detalle del producto tendrá el botón "Mensaje" y será la entrada.
- **Tiempo real sin paquete nuevo:** `SignalRChatRealtime` habla el protocolo JSON de SignalR sobre `dart:io` `WebSocket`.
  - Solo WebSockets, sin negociar, con el token en `?access_token=`.
  - Ping cada 15 s y reconexión con espera (1, 2, 5, 10 y 30 s).
  - Se enciende al abrir `Mensajes` o un chat, y se apaga al cerrar la sesión.
- **Mío o suyo:** se compara `senderId` con el `sub` del access token (`SessionTokens.userId`). Solo se lee: la API valida la firma.

## Contratos
Filas "M-07" de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) (`POST /conversations`, `GET /conversations/{id}`, `GET`/`POST /conversations/{id}/messages` y `WS /hubs/chat`), enlazadas desde `lib/core/network/api_paths.dart`.

## Tests
- `test/features/chat/chat_data_test.dart`:
  - `HttpChatRepository` con `FakeHttpAdapter`;
  - el cliente de SignalR contra un **hub real** (`HttpServer` + `WebSocketTransformer`): saludo, token y `messageCreated`;
  - `SessionTokens.userId` y los formatos de hora.
- `test/features/chat/chat_flow_test.dart` (app completa con el router):
  - tocar un producto abre el chat;
  - historial mío/suyo;
  - enviar;
  - un mensaje rechazado (moderación);
  - un mensaje en tiempo real;
  - mi propia publicación;
  - la guardia de sesión.
- Capturas: `tool/screenshots_test.dart` (`chat-valeria`) comparadas con la maqueta.

## Criterios
- [x] Se puede iniciar un chat desde una publicación → `chat_flow_test`: "tocar un producto en Inicio abre el chat con quien lo vende". Desde solicitudes y ofertas: `NOTE (HU-16)`.
- [x] Cada conversación es entre dos usuarios y está asociada a una publicación (RN-21) → la tarjeta "PUBLICACIÓN DE VALERIA" (`chat_flow_test`); la regla vive en la API.
- [x] Los mensajes de texto se entregan casi en tiempo real (RNF-10) → `chat_data_test` (hub real) y `chat_flow_test`: "lo que llega en tiempo real aparece y se marca leido".
- [x] Solo los participantes pueden leer la conversación (RN-22) → la API responde 404 (`musubi-api:HU-20`); la app exige sesión (`sessionRedirect` en `/chat`).
- [ ] Los mensajes pueden reportarse (RN-23) → `NOTE (HU-28)`.
- [x] `dart format`, `flutter analyze` sin observaciones, `flutter test` 284/284, critic PASS.

## Límites
- "En línea" / "Activa hace 5 min" y el punto verde: `NOTE (HU-21)`. Calificación "★ 4.6": `NOTE (HU-27)`.
- "Ver" (detalle del producto): `NOTE (HU-11)`. "Resumir acuerdo": `NOTE (HU-32)`. "Más opciones" (reportar y bloquear): `NOTE (HU-28)` y `NOTE (HU-57)`. Adjuntar fotos (RF-27): fuera de HU-20.
- Avisos push con la app cerrada: `NOTE (HU-31)`.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 06-Nov-2026
- **Detalle:** 29-Oct-2026: spec ligera (SCRUM-86). 06-Nov-2026 (SCRUM-29): implementada contra `musubi-api` `0.5.0-alpha.1`/`alpha.2` (tiempo real con SignalR + Redis).
