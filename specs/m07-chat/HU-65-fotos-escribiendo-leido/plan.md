# plan.md — HU-65 Enviar fotos y ver "escribiendo…" y "leído" en el chat (app)

## 1. Componentes
- `chat_models.dart`, `chat_repository.dart`, `http_chat_repository.dart` y `signalr_chat_realtime.dart`.
- `chat_providers.dart` (señales y fotos), `chat_controller.dart` y `chat_screen.dart`.
- `ApiPaths.conversationPhotos`.

## 2. Decisiones (con su porqué)
- **Foto por Dio y no por `Image.network`:** la API solo la da con sesión. Así pasa por `AuthInterceptor` (token solo hacia la API, renovación ante 401), y la UI nunca maneja el token.
- **`Typing` como invocación sin respuesta:** es efímero; si se pierde, el siguiente lo repone.
- **"Leído" solo en mi último mensaje:** es lo que se necesita saber. En todos sería ruido.
- **Respuestas rápidas que llenan la caja, sin enviar:** la persona revisa antes de mandar, sobre todo el precio.

## 3. Excepciones al stack
Ninguna (el selector de fotos es el de HU-06).

## 4. Guardarraíles
- El token no sale del interceptor.
- Sin permiso nuevo: la galería es el selector del sistema y la cámara ya estaba aprobada.

## 5. Validación
`flutter analyze`, `flutter test`, `run_integration_tests.ps1` y prueba en el celular (T4).

## 6. Secuencia
T1 → T2 → T3 → T4.
