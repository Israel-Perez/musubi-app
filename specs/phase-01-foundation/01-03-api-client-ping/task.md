# 01-03 — Cliente de API y ping (tareas)

## T1 — Repositorio, estado y pantalla
- **Crear:** `lib/core/network/{api_client,api_paths}.dart`, `lib/core/errors/network_error_message.dart`, `lib/features/status/**`, `test/features/status/**`, `test/helpers/*`.
- **Verificar:** `flutter test` → 18/18; critic PASS.
- **Estado:** ✅ Hecho (15-Oct-2026).

## Pendientes
- `NOTE (HU-02)`: interceptor del token en `createApiClient`.
- `NOTE (02-05)`: timeouts medidos contra la API desplegada; reintentos con backoff.
