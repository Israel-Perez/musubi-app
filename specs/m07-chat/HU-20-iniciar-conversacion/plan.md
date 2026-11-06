# plan.md — HU-20 Iniciar una conversación con el vendedor (app)

## 1. Componentes
- `lib/features/chat/domain/`:
  - `chat_models.dart`: `Conversation`, `ChatContext`, `ChatMessage`, `InboxEntry` e `InboxFilter`;
  - `chat_repository.dart`: `ChatRepository` y `ChatRealtime`.
- `lib/features/chat/data/`:
  - `http_chat_repository.dart` (`dioProvider`, errores con `ApiFailure.fromDio`);
  - `signalr_chat_realtime.dart`.
- `lib/features/chat/presentation/`:
  - `chat_providers.dart` (repositorio, tiempo real, conexión y bandeja);
  - `chat_controller.dart` (`ChatTarget`, `ChatState`, `ChatController`);
  - `chat_screen.dart` y `chat_format.dart`.
- Cambios:
  - `SessionTokens.userId` (`sub` del JWT);
  - íconos `ellipsis`, `send` y `sparkle` (Lucide, desde la maqueta);
  - `ApiPaths` de M-07;
  - rutas `/chat` (con el producto en `extra`) y `/chat/:id`, con guardia de sesión;
  - Inicio: tocar un producto (con sesión) abre el chat.

## 2. Decisiones (con su porqué)
- **Cliente de SignalR propio (unas 150 líneas) en vez de un paquete:** la API solo usa WebSockets sin negociar y un evento. El protocolo JSON (mensajes separados por `0x1E`, saludo, ping tipo 6 y cierre tipo 7) cabe en una clase, y evita una dependencia nueva (regla 00-01). Se prueba contra un hub real local.
- **Enviar por REST:** la app nunca llama métodos del hub. La moderación, los límites y los errores llegan con los códigos que la app ya traduce.
- **El token se renueva por el `AuthInterceptor` en cola** (una petición con sesión) y nunca en paralelo: usar dos veces un refresh token cierra la sesión (02-03).
- **Conexión al abrir `Mensajes` o un chat**, no al arrancar la app: no gasta batería ni red a quien no chatea, y las pruebas del resto de la app no necesitan el chat.
- **Mensajes sin repetir:** el mismo mensaje llega por REST (al enviarlo) y por el hub; se unen por id.
- **Entrada desde Inicio mientras no exista HU-11:** abrir el chat no molesta al vendedor, porque la conversación solo aparece en su bandeja con el primer mensaje.

## 3. Validación
`flutter analyze`, `flutter test` y las capturas `chat-valeria` comparadas con `Chat-Valeria` de la maqueta (Edge headless, `#sesion.Chat-Valeria`).
