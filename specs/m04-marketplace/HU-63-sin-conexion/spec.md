# HU-63 — Abrir la app al instante y consultar sin conexión

**HU / Jira / Sprint / Módulo / Contraparte:** HU-63 / SCRUM-103 / Sprint 5 (14 nov – 1 dic 2026) / M-04 (también chat y pedidos) / N/A (solo la app; usa los endpoints que ya existen)

## Contexto
Jira (SCRUM-103): Como **usuario**, quiero **que la app abra al instante y me deje ver lo último que cargué aunque no tenga internet**, para **usarla con el wifi del campus**.

- Trazabilidad: lineamientos **L-16h** (SQLite + sincronización) y **L-09** (caché en el front). Retoma la decisión de HU-53, que había dejado los datos locales fuera del MVP.
- Pantallas: `Inicio`, `Mensajes`, `Chat-Valeria`, "Mis pedidos" y `Mis-productos`. La maqueta no tiene el aviso de "Sin conexión" ni "Por enviar": se agregan sin quitar nada (lineamiento 4).
- **Decisiones (23-Nov-2026, para que la usuaria las revise):**
  - Se guarda la **primera página** de cada pantalla (la vitrina: 20 recientes, 6 populares, 6 "Se busca" y las categorías). Las respuestas viejas se borran a los **30 días** y un mensaje que no salió, a los **7**.
  - **`sqflite` 2.4.6** (excepción de 00-01; ver `plan.md`).

**Depende de:** `02-01` (sesión y almacén seguro), `02-06` (ETag), `HU-20/22` (chat), `HU-25` (Mis pedidos), `HU-08` (Mis productos), `HU-46` (eliminar la cuenta).

## Requisitos
1. **R1 · Stale-while-revalidate:**
   - Al abrir una de las 4 pantallas por primera vez en la sesión, si hay copia en SQLite se muestra al instante.
   - Al mismo tiempo se pide a la API. Cuando llega, se guarda y la pantalla se vuelve a leer.
   - En los siguientes 30 s se entrega la copia nueva sin otra petición.
   - Después, la red va primero y la copia queda de respaldo.
2. **R2 · Sin conexión:**
   - Si no hay red, se ve lo guardado y, arriba de la barra de pestañas, "Sin conexión · lo que ves puede no estar al día".
   - Cualquier respuesta de la API lo quita.
   - Las acciones que necesitan la API avisan con su mensaje ("No hay conexión con el servidor.").
3. **R3 · "Por enviar":**
   - Un mensaje escrito sin conexión se guarda en SQLite y se ve más tenue, con "Por enviar".
   - Sale solo, en orden, cada 15 s mientras haya pendientes y en cuanto vuelve la red. También al abrir la app si quedó alguno.
   - Si la API lo rechaza al enviarlo (moderación, bloqueo), se quita y se avisa.
4. **R4 · Borrar al salir:** cerrar sesión, una sesión que la API dio por terminada y eliminar la cuenta borran la base local (MASVS-STORAGE).
5. **R5 · Nada sensible sin cifrar:**
   - Los tokens siguen en el almacén seguro; nunca se guardan las respuestas de `/auth`.
   - Antes de escribir se quitan `deliveryCode`, `reference`, `clabe`, `accessToken` y `refreshToken`.
   - La llave de cada copia lleva el id de la cuenta.

## Diseño
- `lib/core/storage/local_store.dart`:
  - `LocalStore`, con `SqliteLocalStore` (tablas `responses` y `outbox`, en el archivo privado de la app; `allowBackup=false`) e `InMemoryLocalStore`;
  - `localStoreProvider`.
- `lib/core/network/offline_cache.dart`:
  - `OfflineCacheInterceptor` es el primero del `dioProvider`, antes del ETag y la sesión;
  - `OfflineCache.options` marca un `GET` que se guarda;
  - también `offlineProvider`, `offlineRefreshedProvider` y `refreshWithOfflineCopies`.
- Se marcan la primera página de `HttpCatalogRepository.homeFeed`, `HttpChatRepository.inbox`, `HttpOrderRepository.mine` y `HttpListingsRepository.minePage`.
- Chat:
  - `lib/features/chat/presentation/chat_outbox.dart` (`ChatOutbox`, lo enciende `MusubiApp`);
  - `ChatMessage.pending` y `ChatController.send` y `load`.
- `lib/core/widgets/offline_banner.dart` en `AppShell`. `SessionController.signOut` borra la base local.

## Contratos
N/A: no cambia la API. Usa `GET /products`, `/categories`, `/wanted`, `/products/popular`, `/conversations`, `/orders/mine`, `/products/mine` y `POST /conversations/{id}/messages` ([`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md)).

## Tests
- `test/core/storage/local_store_test.dart`: con el **motor real de SQLite** (`sqflite_common_ffi`):
  - guardar y reemplazar;
  - el buzón por persona y en orden;
  - borrar todo;
  - las retenciones;
  - sin plugin o con la base dañada, la app sigue.
- `test/core/network/offline_cache_test.dart`:
  - con red guarda sin el código de entrega;
  - sin red, la copia y "Sin conexión";
  - al abrir, la copia al instante y la revalidación en segundo plano;
  - sin copia, el error;
  - otra cuenta no ve la copia;
  - lo no marcado no se guarda;
  - limpiar lo sensible.
- `test/features/chat/chat_flow_test.dart`: "Por enviar" y su envío al volver la red; uno que quedó de antes y la API rechaza.
- `test/core/widgets/offline_banner_test.dart` y `test/core/session/session_test.dart` (`signOut` borra la base local).
- `test/integration/sell_flow_test.dart`: con la API real, "Mis productos" y "Mis pedidos" se guardan; el mismo teléfono con la API apagada los ve y enciende "Sin conexión".
- Toda la suite corre con SQLite real en memoria (`test/flutter_test_config.dart`).

## Criterios
- [x] Las 4 pantallas se guardan en SQLite y abren con lo guardado mientras llega lo nuevo → `al abrir la app entrega lo guardado al instante…`, `sin conexion se ve lo ultimo que cargo`.
- [x] Sin conexión se ve lo guardado con el aviso → `sin red entrega lo guardado…`, `sale sin conexion y se quita al volver la red`.
- [x] Un mensaje sin conexión queda "Por enviar" y sale al volver la red → `sin conexion queda "Por enviar"…`.
- [x] Cerrar sesión o eliminar la cuenta borra la base local → `signOut tambien borra la base local…`, `cerrar sesion lo borra todo`.
- [x] Nada sensible sin cifrar → `con red guarda la respuesta sin el codigo de entrega`, `quita lo sensible en cualquier nivel`, `otra cuenta nunca ve la copia`.
- [ ] Prueba en el celular con el modo avión (T4).

## Límites
- Las acciones (publicar, comprar, apartar) no se desactivan una por una: al tocarlas sin red avisan "No hay conexión con el servidor.".
- Solo el texto del chat se guarda para enviar después, no las fotos (HU-65).
- La copia no está cifrada en el disco: vive en la carpeta privada de la app y sin respaldo, como los datos de cualquier app de Android. Los datos sensibles no se escriben.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 23-Nov-2026 (detallada e implementada)
