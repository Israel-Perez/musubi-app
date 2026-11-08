# HU-57 — Bloquear a un usuario (app, tareas)

## T1 — Bloquear desde el chat
- **Crear:** "Más opciones" (`chatMoreSheet`), el diálogo, `blockCounterpart()` y `_BlockedNotice`.
- **Verificar:** `reputation_flow_test.dart` y las capturas `chat-mas` y `chat-bloquear`.
- **Estado:** ✅ Hecho (08-Nov-2026).

## T2 — "Usuarios bloqueados"
- **Crear:** la fila de Privacidad y `showBlockedUsersSheet`.
- **Verificar:** `reputation_flow_test.dart` y la captura `bloqueados`.
- **Estado:** ✅ Hecho (08-Nov-2026).

## T3 — Foto de la otra persona
- **Cambiar:** `ChatCounterpart.photoUrl` y `ProfileAvatar` en el encabezado y la bandeja.
- **Estado:** ✅ Hecho (08-Nov-2026).

## Pendientes
- `NOTE (HU-05)`: "Ver perfil". `NOTE (HU-31)`: "Silenciar conversación".
