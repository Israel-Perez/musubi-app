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
   - **Sin SQLite en el MVP:** los lineamientos lo piden solo "si el proyecto lo requiere". HU-53 decidió el 08-Nov-2026 no tener modo sin conexión; la caché local queda fuera del MVP.
3. **Guardarraíles DevSecOps**
   - Pruebas de la configuración de Android: si alguien agrega un permiso o activa el backup o el tráfico en claro, el CI falla.
   - `SessionTokens.toString` sin tokens.
   - El token solo viaja a la API, con self-test de mutación.
4. **Validación:** pruebas unitarias, de widgets y de seguridad (80/80), APK de debug y critic/Semgrep.
5. **Secuencia:** tokens y tema → errores → sesión → interceptor → router y barra → componentes → pruebas → documentación.

## Crashlytics (SCRUM-108, 26-Nov-2026)

- **Qué:** `lib/core/observability/crash_reporter.dart`:
  - `CrashReporter` (`FirebaseCrashReporter` y `NoCrashReporter`);
  - `CrashScrubber`;
  - `CrashReportingInterceptor` en `dioProvider` y `publicDioProvider`;
  - en `main.dart`, `FlutterError.onError` y `PlatformDispatcher.onError`.
- **Excepción del stack (00-01):**
  - `firebase_crashlytics` 6.1.0: publisher verificado `firebase.google.com`, licencia BSD-3 (`LICENSE` del paquete), de la misma familia que `firebase_core`/`firebase_messaging`, que ya estaban aprobados con HU-31;
  - el plugin de Gradle `com.google.firebase.crashlytics` 3.0.8 (Google Maven): el ID del build y los símbolos de los fallos nativos;
  - los dos se aplican solo si existe `google-services.json`, como el de los avisos.
- **Alternativa descartada:** Sentry (otra cuenta, otro SDK y su capa gratuita aparte). Crashlytics usa el mismo proyecto de Firebase y no cuesta.
- **Privacidad (MASVS-PRIVACY):**
  - nunca se llama `setUserIdentifier` ni se agregan claves con datos de la persona;
  - cada error pasa por `CrashScrubber`: sin correos, tokens, consultas de URL, números largos ni textos entre comillas;
  - de la API solo sale el método, la ruta sin ids, el estado y el código.
- **Apagado por defecto:** `firebase_crashlytics_collection_enabled=false` en el manifiesto; `FirebaseCrashReporter` lo enciende solo con `kReleaseMode` y Firebase configurado.
- **Remoción:** quitar el paquete, las dos líneas de Gradle y `crash_reporter.dart`; la app queda con `NoCrashReporter` (sin cambios en las pantallas).
