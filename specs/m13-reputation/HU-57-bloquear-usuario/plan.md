# HU-57 — Bloquear a un usuario (app, plan)

## Decisiones
- **El aviso reemplaza la caja de texto:** un bloqueo puede venir de cualquiera de los dos. La API solo dice `canReply`, y la app no revela quién bloqueó.
- **`chat.blocked` al enviar también cambia la caja:** la otra persona pudo bloquear con la conversación abierta.
- **"Ver perfil" y "Silenciar" se muestran:** la maqueta los incluye (lineamiento 4). Avisan "llega muy pronto" hasta HU-05 y HU-31.
- **La lista se quita al instante:** se recuerda a quién se desbloqueó con la hoja abierta y luego se vuelve a pedir la lista, para que Privacidad cuente bien.
- **La foto con `ProfileAvatar`:** el mismo componente del perfil (HU-04), con iniciales si no hay foto o no carga, y la pareja de colores estable de cada persona.

## Archivos
- **Nuevos:** `blocked_users_sheet.dart` y `reputation_providers.dart`.
- **Cambian:** `chat_models.dart`, `http_chat_repository.dart`, `chat_controller.dart`, `chat_screen.dart`, `inbox_screen.dart`, `privacy_screen.dart`, `avatars.dart` y `tool/screenshots_test.dart` (5 escenas).
