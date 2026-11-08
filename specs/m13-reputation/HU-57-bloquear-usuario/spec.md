# HU-57 — Bloquear a un usuario (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-57 / SCRUM-95 / Sprint 3 / M-13 / [musubi-api:HU-57](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m13-reputation/HU-57-bloquear-usuario)

## Contexto
Jira (SCRUM-95): Como **usuario**, quiero **bloquear a otra persona de mi campus**, para **que no pueda escribirme ni ver mis publicaciones**.

- HU nueva (08-Nov-2026). Con HU-28 cumple el requisito de Google Play.
- Maqueta:
  - `chatMoreSheet` → "Bloquear a {nombre}", con el diálogo "¿Bloquear a {nombre}?";
  - Privacidad → "Usuarios bloqueados" (`pvBloq`), con el número o "Ninguno";
  - la hoja `aj-bloqueados`.
- También: la foto de perfil de la otra persona en el chat y en la bandeja (antes solo iniciales), pedida por el usuario el 08-Nov-2026.

**Depende de:** `02-04`, `HU-20`/`HU-22` (chat) y la API `musubi-api:HU-57`.

## Requisitos
1. **R1 · "Más opciones" del chat:** el título es el nombre de la persona y las opciones son las cuatro de la maqueta:
   - "Ver perfil": `NOTE (HU-05)`, aviso "llega muy pronto";
   - "Silenciar conversación": `NOTE (HU-31)`, el mismo aviso;
   - "Bloquear a {nombre}";
   - "Reportar" (HU-28).
2. **R2 · Bloquear:**
   - el diálogo de la maqueta (ícono `ban`, rojo, "Bloquear" y "Cancelar");
   - al confirmar se bloquea, se ve el aviso "Bloqueaste a {nombre}" y la caja de texto cambia por "No puedes responder a esta conversación.".
3. **R3 · Bloqueo que ya existía:**
   - si la API responde `canReply: false` o un envío responde `chat.blocked`, se ve el mismo aviso en lugar de la caja;
   - no dice quién bloqueó.
4. **R4 · "Usuarios bloqueados":**
   - en Privacidad → "Tus datos", primera fila, con el número o "Ninguno";
   - abre la hoja con avatar (foto o iniciales), nombre y "Desbloquear";
   - al desbloquear, la persona sale de la lista con el aviso "Desbloqueaste a {nombre}";
   - sin nadie bloqueado, el texto vacío de la maqueta.
5. **R5 · Foto:** el encabezado del chat y la bandeja muestran la foto de perfil de la otra persona. Sin foto, o si no carga, sus iniciales.

## Diseño
- `ChatController.blockCounterpart()`. `Conversation.canReply` y `Conversation.blocked()`.
- `ChatCounterpart.photoUrl`, que pinta `ProfileAvatar` (ahora con `palette`).
- `showBlockedUsersSheet` y `blockedUsersProvider`. Al desbloquear se invalida la lista, así Privacidad cuenta de nuevo.
- `_BlockedNotice` en lugar de `_Composer`.

## Contratos
Filas `GET`/`POST /api/v1/blocks` y `DELETE /api/v1/blocks/{userId}`; `canReply` y `counterpart.photo` de la conversación y la bandeja ([`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md)).

## Tests
- `reputation_flow_test.dart`:
  - las cuatro opciones; bloquear y cancelar;
  - el aviso con `canReply: false` y con `chat.blocked`;
  - la foto en el encabezado y la bandeja;
  - "Usuarios bloqueados" (número, lista, desbloquear y vacío).
- `http_reputation_repository_test.dart`: bloquear, desbloquear y la lista con su foto.
- Capturas `chat-mas`, `chat-bloquear` y `bloqueados` comparadas con la maqueta.

## Criterios
- [x] Bloquear desde el chat y ver el aviso (R1–R3).
- [x] "Usuarios bloqueados" con desbloquear (R4).
- [x] La foto de la otra persona en el chat y la bandeja (R5).
- [x] `dart format` sin cambios · `flutter analyze` sin observaciones · `flutter test` 100 % · critic PASS.

## Límites
- "Silenciar conversación" depende de los avisos push (`NOTE (HU-31)`).
- "Ver perfil" depende del perfil de otra persona (`NOTE (HU-05)`).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 08-Nov-2026
- **Detalle:** HU nueva por el requisito de Google Play; el aviso sin caja de texto se agrega a la maqueta (lineamiento 4: se agrega, no se quita).
