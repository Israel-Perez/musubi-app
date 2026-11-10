# HU-53 — Guardar productos en favoritos (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-53 / SCRUM-68 / Sprint 4 (9 – 20 nov 2026) / M-04 / [musubi-api:HU-53](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m04-marketplace/HU-53-favoritos)

## Contexto
Jira (SCRUM-68): como **comprador**, quiero **guardar productos en favoritos**, para **volver a encontrarlos rápido y decidir después**.

- Maqueta: `Favoritos` y el corazón de `Producto`; también las tarjetas de `Inicio` y `Busqueda` (sección 10, G-06).
- Trazabilidad: sin RF/RNF en Jira (historia nacida de la maqueta, SCRUM-75); RNF-07 se refleja en la UI y lo aplica el back.
- **Decisión de Jira (08-Nov-2026):** sin modo sin conexión. Los favoritos viven en la API; la caché local de la app queda fuera del MVP.
- **Contrato del corazón (enfoque B):** la app arma el estado con `GET /api/v1/favorites`; los DTOs de productos no cambian. La API local ya implementa las tres filas (`0.5.0-alpha.13`, esquema 13) y su fixture `ContractTest/Fixtures/favorites.json`; no se usa un fake.
- **Bloqueos y borrado de cuenta:** el back aplica `HU-57` (un bloqueo oculta el producto) y `HU-46` (al borrar una cuenta desaparecen sus favoritos); la app solo muestra el estado `unavailable` que devuelve la API.

**Depende de:** `02-01` (sesión, clientes HTTP y errores), `02-04` (piezas de la maqueta), `HU-11` (detalle), `HU-48` (hoja "Crea tu cuenta"), `HU-57`/`HU-46` (reglas del back) y `musubi-api:HU-53`.

## Requisitos
1. **R1 · Corazón de guardar.** En el detalle (`Producto`) y en las tarjetas de `Inicio`, `Busqueda` y `Favoritos`, el corazón agrega o quita el producto:
   - guardado: corazón relleno en color `brand`; no guardado: contorno en `textPrimary`;
   - con sesión, un toque llama a `PUT /api/v1/favorites/{productId}` o `DELETE /api/v1/favorites/{productId}` y actualiza todas las apariciones del producto;
   - sin sesión no se llama a la API: se abre la hoja "Crea tu cuenta" (HU-48) con motivo "guardar" y `returnTo` de la pantalla actual;
   - la API es idempotente: repetir el toque no duplica ni falla.
2. **R2 · Pantalla "Favoritos".** Desde el mosaico `Favoritos` de Perfil (subtítulo "1 guardado" o "N guardados") se abre `/favoritos` dentro de la rama de Perfil, con barra inferior y Perfil activo, como en la maqueta:
   - encabezado con regreso y título "Favoritos";
   - tabs **Todos (N)**, **Disponibles (N)** y **Agotados (N)**; los conteos se derivan de `items` (la fila 79 no los envía) y la pestaña elegida se conserva al volver;
   - mosaico de dos columnas en el orden de la API (más reciente primero) y máximo 200 elementos;
   - `available`: tarjeta normal con foto, estado, precio, título y vendedor; abre el detalle;
   - `soldOut`: tarjeta con "Agotado" al centro, foto atenuada, precio tachado y los datos del producto; abre el detalle;
   - `unavailable`: sin producto, texto "Ya no está disponible", sin abrir detalle; el corazón permite quitarlo y cuenta en la pestaña **Agotados**.
3. **R3 · Estados de la pantalla.** `Favoritos` distingue cargando (indicador, RNF-12), datos, vacío y error:
   - vacío en Todos y Disponibles: "Aún no guardas nada", la explicación "Toca el corazón en cualquier producto para guardarlo aquí." y "Ver lo recién publicado", como la maqueta; vacío en Agotados: "Nada agotado" con la misma explicación y el mismo botón;
   - error: mensaje en español (`ApiFailure.message`) y "Reintentar", sin excepciones de red en la UI.
4. **R4 · Privacidad (RNF-07).** El estado se carga solo con el token y se limpia al cerrar sesión; al entrar con otra cuenta se vuelve a pedir. La app no guarda favoritos en disco ni muestra cuántas personas guardaron un producto o datos de otras cuentas.
5. **R5 · Aviso de la maqueta.** Al guardar: "Guardaste «título»" con "Ver", que abre `Favoritos`. Al quitar: "Lo quitaste de Favoritos" con "Deshacer", que vuelve a guardar; para un `unavailable` sin producto no se ofrece "Deshacer", porque el `PUT` respondería 404. Un fallo de la API conserva el estado anterior y muestra el mensaje traducido, sin dejar el corazón en un estado falso.
6. **R6 · Sin conexión y límites.** No hay modo sin conexión, "Bajó $" ni notificaciones cuando un favorito se agota. La lista no se pagina; el tope de 200 se documenta con `NOTE (HU-53)`. La app no decide autorización: muestra el 401/403/404 que responda la API.

RNF que aplican: RNF-07 (privacidad, reflejado en la UI), RNF-12 (indicador de carga), RNF-18 (español y errores claros), RNF-20 (contraste y escala de fuente) y RNF-27 (tamaños y área táctil).

## Diseño
- **Feature:** `lib/features/marketplace/`, sin crear un módulo nuevo.
- **Dominio:**
  - `domain/favorite_models.dart`: `FavoriteStatus { available, soldOut, unavailable }`, `FavoriteItem { productId, savedAt, status, product }` y `Favorites { items, ids, counts }`; `product` es `ProductSummary?` y el estado desconocido se trata como `unavailable`.
  - `domain/favorites_repository.dart`: `list()`, `add(productId)` y `remove(productId)`; lanzan `ApiFailure`, nunca `DioException`.
- **Datos:** `data/http_favorites_repository.dart` sobre `dioProvider`; parsea la respuesta con tolerancia (un elemento inválido no tumba la lista) y traduce `DioException` con `ApiFailure.fromDio`.
- **Rutas:** `lib/core/network/api_paths.dart` suma `favorites` y `favorite(productId)`, citando las filas 79–81 de `musubi-api/docs/endpoints.md`.
- **Estado:**
  - `presentation/favorites_providers.dart`: `favoritesRepositoryProvider` y `favoritesProvider` (`AsyncNotifier<Favorites>`); escucha el `userId` de `sessionControllerProvider` (no cada renovación de token), carga al entrar y devuelve vacío con visitante;
  - `toggle(ProductSummary)`, `add(FavoriteItem)` y `remove(String)` actualizan el estado después de la respuesta de la API; un `Set` de ids en vuelo evita dobles toques;
  - `favoriteTabProvider` conserva Todos/Disponibles/Agotados.
- **UI compartida:**
  - `presentation/favorites_actions.dart`: helper con el aviso "Ver"/"Deshacer" y el manejo de `ApiFailure`;
  - `home_cards.dart`: `SaveButton` pasa a `ConsumerWidget` y calcula el corazón relleno con `favoritesProvider`; `onSave` de las tarjetas recibe el `ProductSummary`;
  - `home_screen.dart`, `search_screen.dart` y `product_screen.dart` conectan el toque; el detalle construye el `ProductSummary` que necesita el proveedor con los datos de `ProductDetail` y reutiliza el mismo estado en su botón redondo;
  - `profile_screen.dart`: mosaico "Favoritos" antes de "Privacidad", con el conteo de la API.
- **Pantalla:** `presentation/favorites_screen.dart` con tabs, mosaico y tarjeta propia para los tres estados; reutiliza `ProductPhoto`, `StockPill`, `formatPrice` y `Pressable`.
- **Ruta:** `app/router.dart` agrega `AppRoutes.favorites = '/favoritos'` dentro de la rama de Perfil, la suma a `requiresSession` y la abre desde el mosaico.
- **Sin fake de endpoint:** las filas existen; no se agrega `NOTE (musubi-api:HU-53)`. El `fake_favorites_repository.dart` es solo para pruebas y capturas.

## Contratos
- Filas canónicas de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md), sección `## M-03 · Publicaciones`, filas 79–81:
  - `GET /api/v1/favorites` → `FavoritesResponse { items: FavoriteItemResponse[] }`, con `status` `available`/`soldOut`/`unavailable`, `product` `ProductResponse?`, del más reciente al más viejo y máximo 200;
  - `PUT /api/v1/favorites/{productId}` → `204`; `404 listings.product_not_found` si la publicación no es visible;
  - `DELETE /api/v1/favorites/{productId}` → `204` idempotente.
- Fixture de forma JSON: `musubi-api/ContractTest/Fixtures/favorites.json`.
- La app solo distingue por `code`: `auth.forbidden` (403), `listings.product_not_found` (404), `5xx` y los `network.*`; el catálogo de errores vive en `musubi-api/docs/errores.md`.
- **Sin cambios** en `ProductResponse`, `ProductDetailResponse` ni en las filas de productos: el corazón se arma con `GET /favorites` (enfoque B del back).

## Tests
- `test/features/marketplace/data/http_favorites_repository_test.dart`:
  - `GET` 200 mapea `available`, `soldOut` y `unavailable`, `product: null`, `savedAt` en UTC y el orden;
  - un elemento incompleto o un `status` desconocido no tumba la lista;
  - `PUT` 204, `PUT` 403 `auth.forbidden`, `PUT` 404 `listings.product_not_found`, `DELETE` 204, 401, 5xx y sin red llegan como `ApiFailure`.
- `test/features/marketplace/favorites_providers_test.dart`:
  - con sesión carga la lista; con visitante queda vacío y no llama al repositorio;
  - `toggle` agrega y quita, actualiza `ids`/conteos y no duplica con dos toques;
  - un fallo conserva el estado anterior;
  - al cambiar de usuario se recarga y al cerrar sesión se limpia (RNF-07).
- `test/features/marketplace/favorites_screen_test.dart`:
  - cargando, error + "Reintentar", vacío y los tres estados en el mosaico;
  - tabs y conteos; `unavailable` en **Agotados** y sin abrir el detalle; quitar desde el corazón;
  - `meetsGuideline(textContrastGuideline)` y `MinimumTapTargetGuideline(size: Size(44, 44))`; sin overflow a 360×640 y en tablet.
- `test/features/marketplace/product_screen_test.dart`: el corazón del detalle alterna, refleja el estado guardado y, sin sesión, abre "Crea tu cuenta" sin llamar a la API.
- `test/features/marketplace/home_screen_test.dart` y `search_screen_test.dart`: el corazón de una tarjeta guarda el producto correcto; el visitante abre la hoja de cuenta; "Ver" abre Favoritos y "Deshacer" vuelve a guardar.
- `test/features/marketplace/visitor_flow_test.dart`: el visitante que toca el corazón de Inicio no llama a la API.
- `test/features/marketplace/favorites_screen_test.dart`: además de los estados, `soldOut` abre el detalle y el vacío de Agotados dice "Nada agotado".
- `test/features/profile/profile_flow_test.dart`: el mosaico "Favoritos" muestra el conteo y abre `/favoritos`.
- `test/helpers/fake_favorites_repository.dart`: lista, acciones, errores y un estado pendiente, sin red; es un fake de pruebas, no sustituye al endpoint.
- `tool/screenshots_test.dart`: escena `favoritos` a 390×844, en claro y oscuro, comparada con la maqueta.
- `flutter test` se reporta con el conteo real al cerrar; no se fija un número antes de ejecutarlo.

## Criterios
- [x] Desde el detalle y desde una tarjeta, el corazón guarda y quita el producto, y todas las apariciones cambian juntas (R1) → pruebas de data, provider y widget.
- [x] El visitante que toca el corazón ve "Crea tu cuenta" y no se llama a la API (R1) → widget test de Inicio/Búsqueda/Producto.
- [x] `Favoritos` lista los tres estados, los tabs filtran y los conteos coinciden (R2/R3) → `favorites_screen_test.dart`.
- [x] El producto `unavailable` dice "Ya no está disponible" y no abre el detalle (R2) → widget test.
- [x] Al cerrar sesión el estado queda vacío y no se mezclan cuentas, ni con una petición en vuelo (R4) → `favorites_providers_test.dart`.
- [x] Los errores se muestran en español y "Reintentar" vuelve a pedir la lista (R3) → data + widget tests.
- [x] "Ver" abre Favoritos y "Deshacer" vuelve a guardar (R5) → `home_screen_test.dart`.
- [x] Sin modo sin conexión ni almacenamiento local (R6): `grep -R "shared_preferences\|sqflite\|File(" lib/features/marketplace` sin resultados; la app solo lee de la API y muestra el 401/403/404 traducido → data tests.
- [x] La captura `favoritos` mide 390×844 y coincide con la maqueta en claro y oscuro (R2) → `tool/screenshots_test.dart`.
- [x] `dart format --output=none --set-exit-if-changed .` sin cambios · `flutter analyze --fatal-infos --fatal-warnings` 0 · `flutter test` 454/454 · `pwsh scripts/critic-guardrails.ps1` PASS.
- [x] `semgrep scan --config=auto --config=.semgrep/semgrep.yaml --error` sin hallazgos en el CI del PR #44.

## Límites
- **Sin modo sin conexión** (decisión de Jira, 08-Nov-2026): no hay SQLite, caché de favoritos ni vitrina offline. La app no promete "Guardado en tu teléfono".
- **Sin "Bajó $"** de la maqueta: no hay historial de precios en esta HU.
- **Sin paginación:** la lista devuelve hasta 200; si una persona supera el tope, se pagina en una HU posterior. `NOTE (HU-53)`.
- **Sin notificaciones** cuando un favorito se agota o baja de precio; el estado se recalcula al consultar.
- **Sin calificación del vendedor en la tarjeta:** `ProductResponse` solo trae `seller.name` en la fila 79; la maqueta muestra ★.
- **Sin cambios en productos:** la vitrina pública sigue cacheable; no se agrega `isFavorite` a `ProductResponse`.
- **Sin regla contra guardar una publicación propia:** el back lo permite; no aporta al comprador y no daña.
- **Datos locales de otras HU:** el borrador de HU-06, el historial de búsqueda de HU-09/HU-10 y la caché de 02-06 no se implementan aquí. Las specs que los atribuían a HU-53 se concilian en `task.md` → T1.
- **Pendiente con dueño:** despliegue de la API `0.5.0-alpha.13` → `musubi-api:HU-53`; revisor de esta spec → usuario.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 09-Nov-2026
- **Detalle:**
  - spec detallada el 09-Nov-2026; implementación y pruebas completadas el mismo día;
  - se adopta el enfoque B del back: `GET /favorites` arma el corazón y los DTOs de productos no cambian;
  - se resuelve la decisión pendiente de Jira: sin modo sin conexión;
  - las filas 79–81 existen en la API local (`0.5.0-alpha.13`, esquema 13), con fixture; no hay fake de endpoint;
  - el aviso de la maqueta se conserva con "Ver" y "Deshacer";
  - evidencia: `flutter test` 454/454, analyze 0, format 0, critic PASS, captura `favoritos` claro/oscuro (1170×2532), APK debug, `security-reviewer` PASS y `semgrep` PASS en el CI del PR #44;
  - pendiente: la aprobación de un revisor.
