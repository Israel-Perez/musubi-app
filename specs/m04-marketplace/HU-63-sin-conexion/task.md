# HU-63 — Abrir la app al instante y consultar sin conexión (tareas)

## T1 — Detallar la spec
- **Estado:** ✅ Hecho (23-Nov-2026). Decisiones para revisar: primera página de cada pantalla, 30 y 7 días, y `sqflite`.

## T2 — Base local e interceptor
- **Qué:** `LocalStore` (SQLite), `OfflineCacheInterceptor` y las marcas en los 4 repositorios.
- **Prueba:** `test/core/storage/local_store_test.dart` y `test/core/network/offline_cache_test.dart`.
- **Estado:** ✅ Hecho.

## T3 — Pantallas
- **Qué:** "Sin conexión" en `AppShell`, "Por enviar" en el chat, el buzón y borrar al cerrar sesión.
- **Prueba:** `test/features/chat/chat_flow_test.dart`, `test/core/widgets/offline_banner_test.dart`, `test/core/session/session_test.dart` y `test/integration/sell_flow_test.dart`.
- **Estado:** ✅ Hecho.

## T4 — Prueba en el celular
- **Qué:**
  1. Abrir las 4 pantallas con red.
  2. Activar el modo avión y volver a abrirlas: se ven, con "Sin conexión".
  3. Escribir un mensaje: queda "Por enviar".
  4. Quitar el modo avión: sale solo.
  5. Cerrar sesión y confirmar que no queda nada.
- **Estado:** ⏳ Por hacer (siguiente lote de Google Play).
