# HU-65 — Enviar fotos y ver "escribiendo…" y "leído" en el chat (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-65 / SCRUM-105 / Sprint 5 (14 nov – 1 dic 2026) / M-07 / [musubi-api:HU-65](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m07-chat/HU-65-fotos-escribiendo-leido)

## Contexto
Jira (SCRUM-105): Como **usuario**, quiero **mandar fotos en el chat, ver cuando la otra persona escribe o leyó mi mensaje y usar respuestas rápidas**, para **ponernos de acuerdo más rápido**.

- Pantalla: `Chat-Valeria`.
  - El "+" de la caja ya estaba en la maqueta y hasta ahora decía "llega muy pronto".
  - Lo demás se agrega sin quitar nada (lineamiento 4), con las piezas de 02-04.
- **Decisiones (24-Nov-2026):**
  - La foto se baja con la sesión (Dio), no con una URL pública.
  - "¿Aceptas $X?" propone un 10 % abajo del precio, en pesos de 10 en 10.

**Depende de:** `HU-20/22` (chat), `HU-57` (bloquear), `HU-06` (selector de fotos), `HU-63` (buzón "Por enviar").

## Requisitos
1. **R1 · Foto:**
   - El "+" abre "Enviar una foto" con "Tomar foto" y "Elegir de la galería" (el selector de HU-06, sin permiso de almacenamiento).
   - La foto se envía y se ve como una burbuja cuadrada.
   - Si la API la rechaza (moderación), se muestra su mensaje.
2. **R2 · Ver la foto:** se baja con `chatPhotoProvider` (con sesión, por Dio) y se queda en memoria; mientras carga, un esqueleto.
3. **R3 · "Escribiendo…":**
   - Al escribir, la app avisa por el hub (`Typing`) a lo más cada 3 s.
   - "Valeria está escribiendo…" sale arriba de la caja y se va a los 5 s o al llegar su mensaje.
4. **R4 · "Leído":** debajo de mi último mensaje, si la otra persona abrió la conversación después. Se actualiza en tiempo real (`conversationRead`).
5. **R5 · Respuestas rápidas:** en una conversación sin mensajes, quien compra ve "¿Sigue disponible?", "¿Dónde nos vemos?" y "¿Aceptas $X?". Tocar una la escribe en la caja; la persona la envía o la cambia.
6. **R6 · Bloqueo:** sin caja (HU-57) no hay clip, ni respuestas rápidas, ni se avisa "escribiendo…"; tampoco se ve "Leído".

## Diseño
- Datos:
  - `ChatMessage.photoPath` / `isPhoto`;
  - `Conversation.counterpartReadAt` / `readAt`;
  - `TypingSignal` y `ReadSignal`.
- `ChatRepository.sendPhoto` y `photo`.
- Hub: `ChatRealtime.typing`, `reads` y `sendTyping` (invocación sin respuesta).
- Providers: `chatTypingProvider`, `chatReadsProvider` y `chatPhotoProvider`.
- `ChatController`: `typed`, `sendPhoto` y las señales.
- `chat_screen.dart`: `_attach`, `_PhotoBubble`, `_TypingLine`, `_QuickReplies` y el sello "Leído".

## Contratos
Filas `POST /api/v1/conversations/{id}/photos`, `GET …/photos/{name}`, `POST …/read` y `WS /hubs/chat` de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md).

## Tests
- `test/features/chat/chat_data_test.dart`:
  - el multipart y la descarga de la foto;
  - `counterpartReadAt`;
  - el hub real con `typing`, `conversationRead` y la invocación `Typing`.
- `test/features/chat/chat_flow_test.dart`:
  - foto de la galería;
  - foto rechazada;
  - "Escribiendo…" y su límite;
  - "Leído";
  - las respuestas rápidas.
- `test/integration/chat_flow_test.dart`: contra la API real, la foto, su descarga, la rechazada, "escribiendo…" y "leído" por el hub.

## Criterios
- [x] Enviar una foto de la cámara o la galería, moderada → `el clip envia una foto…`, `una foto rechazada…`, `fotos, "escribiendo…" y "leído"`.
- [x] "Escribiendo…" en tiempo real → `"Escribiendo…" llega y se va…`.
- [x] "Leído" → `"Leído" sale bajo mi ultimo mensaje…`.
- [x] Respuestas rápidas en la primera conversación → `respuestas rapidas en la primera conversacion…`, `con mensajes ya no salen…`.
- [x] Con un bloqueo nada funciona → API (`chat.blocked`, sin `typing` ni "Leído") y `Conversation.blocked()`.
- [ ] Prueba en el celular (T4).

## Límites
- Las fotos no se guardan para enviar después sin conexión: solo el texto (HU-63).
- La foto no se abre a pantalla completa.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 24-Nov-2026 (detallada e implementada)
