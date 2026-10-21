# 02-01 — Base de la app (tareas)

## T1 — Tema de la maqueta
- **Crear:** `lib/core/theme/musubi_tokens.dart` y `assets/fonts/` (TTF de `tokotype/PlusJakartaSans@18d1cd2f7ea10481919d2f05c1f7064b7307fc26`, OFL).
- **SHA-256:**

  | Archivo | SHA-256 |
  |---|---|
  | `Regular` | `bd6276d4060e3b1ebc45047469e0bb86b08f301ba681cdf1ceb6245ea10478d2` |
  | `Medium` | `c77bab757d7402ec6d9341d5f7ddaafb2474e17026792697ba4624c7dc89caf7` |
  | `SemiBold` | `65dbcedb6596a41c30869729eb31cb57d1f5edfe365684314bba8a1994eaa4cb` |
  | `Bold` | `5f5342ef76862b5b5365d1dff1a667629dfa484e388dd602552f647219c3870f` |
  | `ExtraBold` | `7d60d21b5dec501c77437e80aabd539f1d7a7b0ac7d4ada361d4d42abc7c55ea` |

- **Verificar:** `test/core/theme/app_theme_test.dart` y las guías de accesibilidad de `widgets_test.dart`.
- **Estado:** ✅ Hecho (21-Oct-2026).

## T2 — Sesión y cliente HTTP
- **Crear:** `lib/core/session/{session_tokens,token_store,session_controller,auth_interceptor}.dart`.
- **Modificar:** `lib/core/network/api_client.dart` y `lib/main.dart`.
- **Verificar:** `test/core/session/*` y el self-test del host.
- **Estado:** ✅ Hecho (21-Oct-2026).

## T3 — Navegación y componentes
- **Crear:** `lib/app/shell/*`, `lib/core/widgets/*` y `lib/core/errors/api_failure.dart`.
- **Modificar:** `lib/app/router.dart`.
- **Verificar:** `test/app/navigation_test.dart`, `test/core/widgets/widgets_test.dart` y `test/core/errors/api_failure_test.dart`.
- **Estado:** ✅ Hecho (21-Oct-2026).

## T4 — Seguridad de Android
- **Crear:** `test/security/android_config_test.dart`.
- **Estado:** ✅ Hecho (21-Oct-2026).

## Pendientes
- ~~`NOTE (HU-02)`: renovación HTTP y logout contra la API~~ → resuelto en HU-02 (`HttpSessionApi`, `SessionController.logOut`, 21-Oct-2026).
- `NOTE (HU-48)`: aviso "Crea tu cuenta" antes de mandar al visitante a iniciar sesión.
- `NOTE (HU-15, HU-22, HU-04, HU-06, HU-13)`: reemplazar cada `UpcomingSection` por su pantalla.
- `NOTE (HU-31)`: Firebase (FCM y Crashlytics). `NOTE (02-05)`: timeouts medidos contra la API desplegada.
- `NOTE (HU-53)`: decidir los datos locales (SQLite o caché) para favoritos sin conexión.
