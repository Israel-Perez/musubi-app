# plan.md — 02-01 Base de la app

1. **Mapeo de componentes e impacto**
   - **Crear:**
     - `lib/core/theme/musubi_tokens.dart`, `lib/core/session/*`, `lib/core/errors/api_failure.dart`, `lib/core/widgets/*`;
     - `lib/app/shell/*` y `assets/fonts/*`;
     - las pruebas de `test/{app,core,security}/`.
   - **Modificar:** `app_theme.dart`, `router.dart`, `api_client.dart`, `main.dart`, `pubspec.yaml` (fuente y `flutter_secure_storage`) y `.gitattributes` (`*.ttf binary`).
2. **Decisiones de arquitectura**
   - **Fuente empaquetada y no `google_fonts`:** no descarga nada en tiempo de ejecución (privacidad, funciona sin red) y la versión queda fijada en el repo.
   - **`ThemeExtension` con los tokens:** los componentes leen `context.musubi.brand` y no números sueltos. El modo oscuro sale del mismo mapa del prototipo.
   - **La sesión se lee en `main()` antes de pintar:** sin estado intermedio ni redirecciones dobles al abrir.
   - **`QueuedInterceptor` + comparación del token enviado:** una sola renovación por ola de errores 401. El reintento sale por el cliente público, porque reintentar con el mismo cliente se bloquea (*deadlock*). Lo encontró la prueba "sin bucle".
   - **Guardia pura (`sessionRedirect`):** se prueba sin widgets. Al regreso con `?desde=` solo se aceptan rutas conocidas, para evitar una redirección abierta.
   - **Sin SQLite en el MVP:** los lineamientos lo piden solo "si el proyecto lo requiere". Se revisa en HU-53.
3. **Guardarraíles DevSecOps**
   - Pruebas de la configuración de Android: si alguien agrega un permiso o activa el backup o el tráfico en claro, el CI falla.
   - `SessionTokens.toString` sin tokens.
   - El token solo viaja a la API, con self-test de mutación.
4. **Validación:** pruebas unitarias, de widgets y de seguridad (80/80), APK de debug y critic/Semgrep.
5. **Secuencia:** tokens y tema → errores → sesión → interceptor → router y barra → componentes → pruebas → documentación.
