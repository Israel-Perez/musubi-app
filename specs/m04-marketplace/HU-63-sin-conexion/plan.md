# plan.md — HU-63 Abrir la app al instante y consultar sin conexión

## 1. Componentes
- `lib/core/storage/local_store.dart` (SQLite y en memoria) y `lib/core/network/offline_cache.dart` (el interceptor y su estado).
- `api_client.dart`: el interceptor va primero en `dioProvider`.
- Los 4 repositorios marcan su primera página; sus providers usan `refreshWithOfflineCopies`.
- `chat_outbox.dart`, `chat_controller.dart`, `chat_screen.dart` y `ChatMessage.pending`.
- `offline_banner.dart` en `app_shell.dart`; `session_controller.dart` (`signOut`).
- `test/flutter_test_config.dart` (SQLite real en las pruebas).

## 2. Decisiones (con su porqué)
- **En el interceptor de Dio, no en cada modelo:** se guarda la respuesta JSON tal como llega, así cada repositorio la vuelve a leer con el mismo parser. No hay que escribir serializadores para los modelos.
- **Solo lo marcado:** `OfflineCache.options` en la primera página de 4 pantallas. Una búsqueda o un detalle no llenan el teléfono.
- **Stale-while-revalidate con `FutureProvider`:** la pantalla recibe la copia y, al llegar la red, el provider se vuelve a construir (`offlineRefreshedProvider`). Las pantallas no cambian.
- **Sanitizar antes de escribir:** `/orders/mine` trae el código de entrega y la referencia de cada pedido. No se escriben.
- **El buzón vive en `MusubiApp`, no en el chat abierto:** un mensaje sale aunque la persona ya no esté en esa conversación.

## 3. Excepciones al stack (regla de 00-01)
- **`sqflite` 2.4.6** (dependencia):
  - Publicado el 10-Nov-2026 (cooldown de 7 días cumplido), por tekartik.com (publisher verificado), con licencia BSD-2-Clause.
  - Es el paquete de referencia de SQLite en Flutter, sin avisos de seguridad.
  - Lo exige el lineamiento L-16h ("SQLite").
- **`path` 1.9.1** (dependencia): de dart.dev, BSD-3. Ya venía como transitiva; ahora es directa porque `local_store.dart` la usa.
- **`sqflite_common_ffi` 2.4.7** (solo pruebas):
  - Publicado el 11-Nov-2026, del mismo autor y con licencia BSD-2-Clause.
  - Corre el motor real de SQLite en la VM.
  - Trae `sqlite3` 3.9.2, que provee SQLite con sus build hooks.
- **Alternativas descartadas:**
  - `drift`: requiere `build_runner` y codegen, y este repo no usa codegen.
  - `hive` / `shared_preferences`: no son SQLite, que es lo que pide el lineamiento.
- **Plan de remoción:**
  1. Quitar `localStoreProvider`, el interceptor y el buzón.
  2. Las pantallas siguen funcionando, solo sin conexión no muestran nada.
- **Aprobación:** propuesta por el agente el 23-Nov-2026. La aprueba la usuaria al fusionar el PR.

## 4. Guardarraíles
- MASVS-STORAGE: nada de `/auth` ni tokens; se quitan los datos sensibles; se borra al cerrar sesión; la llave lleva el id de la cuenta; `allowBackup=false` (ya probado en `android_config_test.dart`).
- Si SQLite falla, la app sigue sin copias (nunca truena por la base local).

## 5. Validación
`flutter analyze`, `flutter test` (con SQLite real), `run_integration_tests.ps1` y prueba en el celular con el modo avión (T4).

## 6. Secuencia
T1 → T2 → T3 → T4.
