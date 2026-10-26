# 02-01 — Base de la app: tema de la maqueta, navegación, sesión segura y errores

**HU / Jira / Sprint / Módulo / Contraparte:** N/A (spec técnica) / SCRUM-79 / S2 / transversal / contraparte: `musubi-api:02-03` (errores `problem+json` con `code`, JWT y refresh rotativo)

## Contexto
Las pantallas del login (HU-01, HU-02, HU-03, HU-47 y HU-56) y del resto de la app necesitan:
- el sistema visual de la maqueta (lineamiento 4);
- la barra de 5 pestañas;
- una sesión segura que no muera salvo logout (L-16g, L-10);
- una forma única de mostrar los errores de la API (RNF-18).

Esta spec deja esa base y las primeras pruebas de seguridad del móvil (L-07). **Depende de**: `01-02` (shell), `01-03` (cliente de API) y `musubi-api:02-03`.

## Requisitos
1. **Tema de la guía de estilo** (`docs/maqueta/README.md`, sección 1):
   - Plus Jakarta Sans 400–800 empaquetada (OFL, sin descargas);
   - colores claros y oscuros con el mapa del prototipo;
   - escala tipográfica, radios y alturas de botón (56/48/44).
   - Todo texto cumple contraste AA (RNF-20) y toda acción tiene un área táctil de al menos 44 dp (RNF-27).
2. **Barra inferior de la maqueta:** Inicio, Se busca, Publicar (botón central de 52 dp), Mensajes y Perfil. Cada pestaña conserva su pila de navegación. El visitante explora Inicio y Se busca; Publicar, Mensajes y Perfil piden sesión. El regreso después de iniciar sesión solo acepta rutas internas conocidas.
3. **Sesión:**
   - los tokens viven en el almacén cifrado del sistema (`flutter_secure_storage`, Android Keystore) y se leen antes de pintar la app;
   - el logout los borra del dispositivo;
   - un almacén dañado no bloquea la app.
4. **Cliente HTTP:**
   - el access token se agrega **solo** a peticiones hacia el mismo esquema, host y puerto de la API;
   - ante un 401 la sesión se renueva **una sola vez** aunque fallen varias peticiones a la vez;
   - si la renovación se rechaza, la sesión termina.
5. **Errores:** `ApiFailure` traduce el `problem+json` de la API (`code`, `title` y `errors` por campo) y los errores de red (códigos `network.*` propios). La UI decide por `code`.
6. **Componentes base:**
   - botón con estado de carga, que evita envíos dobles;
   - campo con etiqueta arriba, error de la API y botón para ver la contraseña;
   - aviso en línea con icono (nunca solo color);
   - vistas de carga, vacío y error con reintento.
7. **Seguridad de Android (L-07, MASVS):**
   - sin backup;
   - solo los permisos aprobados;
   - release sin tráfico en claro;
   - debug y profile solo hacia `10.0.2.2`;
   - sin archivos de Firebase ni de firma versionados.

## Diseño
- **Tema:** `lib/core/theme/musubi_tokens.dart` (`MusubiColors` como `ThemeExtension`, `MusubiSizes`, `MusubiType`) y `app_theme.dart` (`ThemeData` claro y oscuro, `context.musubi`). En modo oscuro el relleno rojo de los botones se conserva, como en `fillKeep` del prototipo, y el texto rojo usa `#FF5C61`.
- **Navegación:** `lib/app/router.dart`.
  - `StatefulShellRoute.indexedStack` con 4 ramas; Publicar es una ruta aparte.
  - `sessionRedirect` es una función pura y probada.
  - `refreshListenable` escucha la sesión, así que el router reevalúa la guardia sin recrearse.
  - La barra es `lib/app/shell/musubi_bottom_bar.dart`.
  - Las secciones sin HU muestran `UpcomingSection` con su `NOTE (HU-NN)`.
- **Sesión:** `lib/core/session/`.
  - `SessionTokens` (sin `toString` de los tokens) y `TokenStore` (`SecureTokenStore` con una sola llave).
  - `SessionController` (`Visitor` o `SignedIn`): escribe en el almacén antes de cambiar el estado.
  - `AuthInterceptor` (`QueuedInterceptor`).
  - Hay dos clientes HTTP: `publicDioProvider` (sin sesión, para renovar y para `/auth`) y `dioProvider` (con el interceptor). El reintento sale por el cliente público para evitar el *deadlock* de reintentar dentro de un `QueuedInterceptor`.
- **Errores:** `lib/core/errors/api_failure.dart`.
- **Componentes:** `lib/core/widgets/` (`MusubiButton`, `MusubiTextField`, `InlineMessage`, `LoadingView`, `EmptyView`, `ErrorView`).
- **Íconos:** Material *outlined* en lugar de un paquete Lucide; son equivalentes de trazo y evitan una dependencia (regla de excepción de 00-01).
- **Permisos:** solo `INTERNET`. Cámara y galería (HU-06) y notificaciones (HU-31) se piden **en contexto**, en el momento de usarlas y con explicación previa. Cada permiso nuevo se agrega a la lista aprobada de `test/security/android_config_test.dart` en su HU.
- **Datos locales:** en el MVP no hay SQLite (lineamiento 16, "si el proyecto lo requiere"). Se decide en HU-53 (favoritos sin conexión) con una fila nueva en esta spec.

## Contratos
- Errores: `musubi-api/docs/errores.md` (se enlaza). Los códigos `network.*` y `request.rejected` son de la app y la API nunca los envía.
- Sesión: tokens de `musubi-api:02-03`. Los endpoints de login, refresh y logout llegan con HU-02 (`NOTE (HU-02)` en `sessionRefresherProvider` y `SessionController.signOut`).
- Configuración: sin claves nuevas. `flutter_secure_storage` 11.2.0 (BSD-3) es la única dependencia nueva.

## Tests
- `test/core/theme/app_theme_test.dart` (20): contraste ≥ 4.5:1 de 9 pares en claro y en oscuro, marca distinta del error, fuente, alto de botón, radio de campo y área táctil.
- `test/core/errors/api_failure_test.dart` (4): `problem+json`, errores por campo, respuesta sin `code` y errores de red.
- `test/core/session/session_test.dart` (8): codificar y decodificar, valores corruptos, `toString` sin tokens, inicio como visitante o con sesión, `signIn` y `signOut`.
- `test/core/session/auth_interceptor_test.dart` (7):
  - el token solo va a la API (no a otro host, esquema o puerto);
  - un visitante no envía token;
  - renueva y reintenta;
  - 4 errores 401 a la vez producen 1 sola renovación;
  - una renovación rechazada termina la sesión;
  - no hay bucle.
- `test/app/navigation_test.dart` (9): guardia, regreso seguro, 5 opciones, visitante en Se busca y en Perfil, con sesión en Perfil y logout que saca de Perfil.
- `test/core/widgets/widgets_test.dart` (7): carga, alto de 56 dp, campo con error y contraseña visible, aviso, reintento y `textContrastGuideline` + `androidTapTargetGuideline` en claro y oscuro.
- `test/security/android_config_test.dart` (5): backup, permisos, tráfico en claro por variante y archivos sensibles.

## Criterios
- `dart format` sin cambios · `flutter analyze --fatal-infos --fatal-warnings` sin hallazgos · `flutter test` 80/80.
- `flutter build apk --debug` → `√ Built`.
- Self-test: si el interceptor acepta cualquier host, falla la prueba "nunca envía el token a otro host" (21-Oct-2026).
- `pwsh scripts/critic-guardrails.ps1` → PASS · Semgrep → 0.

## Límites
- La renovación HTTP y el logout contra la API llegan con HU-02. Mientras tanto, un 401 con sesión cierra la sesión local.
- `UpcomingSection` muestra texto provisional en las secciones sin HU (Se busca, Mensajes, Perfil y Publicar).
- La fuente se fijó al commit `18d1cd2` de `tokotype/PlusJakartaSans`. Los SHA-256 de los TTF están en `task.md`.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 21-Oct-2026
- **Detalle:** Paquete nuevo: `flutter_secure_storage` 11.2.0 (BSD-3, publicado el 16-Sep-2026), previsto en la constitución §6. Plus Jakarta Sans (OFL 1.1) empaquetada con su licencia en `assets/fonts/OFL.txt` y registrada en `LicenseRegistry`.
