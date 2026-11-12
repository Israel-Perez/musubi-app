# HU-05 — Consultar perfil y reputación de otro usuario (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-05 / SCRUM-34 / Sprint 4 (9–20 nov 2026) / M-02 (consume M-03 y M-04) / [musubi-api:HU-05](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m02-profile/HU-05-perfil-publico)

## Contexto
Jira (SCRUM-34): Como **usuario**, quiero **consultar el perfil y la reputación de otro usuario**, para **decidir si hago un trato con él**.

- **Maqueta `Perfil-vendedor`:** foto (o iniciales), nombre, carrera y periodo, reputación con estrella, número de calificaciones, ventas, “En Musubi desde {mes año}” y dos pestañas: **Publicaciones (N)** y **Opiniones (N)**. Se abre desde la tarjeta de quien vende en `Producto` y desde “Ver perfil” en `Chat-Valeria`.
- **Decisión de Jira (08-Nov-2026):** el alcance del sprint es nombre, foto, campus y publicaciones activas; la reputación se muestra como **“Sin calificaciones”** mientras no existan calificaciones (RN-26). No se expone el correo ni datos privados (RNF-05). “Seguir”, “Responde en” y “Mensaje” no entran (ver Límites).
- **Contraparte en Borrador con evidencia (11-Nov-2026):** `musubi-api:HU-05` (`0.5.0-alpha.21`, esquema 19) reutiliza `GET /profiles/{id}` y `GET /products?sellerId=&hideSoldOut=true`; no hay DTO ni ruta nueva.
- Trazabilidad: RF-05, RF-14, RF-36 · CU-03 · RN-26.

**Depende de:** `02-01` (tokens y cliente HTTP), `02-03` (sesión y errores), `02-04` (piezas de la maqueta), `HU-04` (perfil y visibilidad), `HU-11` (detalle del producto) y `HU-20` (chat). **Diferido:** `HU-27`/`HU-45` (calificaciones y opiniones).

## Requisitos
1. **Cabecera del perfil público (RF-05, RNF-05, RNF-07):**
   - `GET /api/v1/profiles/{id}` da foto, nombre, campus, carrera, periodo, “En Musubi desde” y `stats { ratingAvg, ratingCount, sales }`.
   - La pantalla muestra la foto o las iniciales, el nombre con “Verificada”, el subtítulo `UTTT · Ing. Mecatrónica · 9º cuatrimestre` y “En Musubi desde oct 2024”.
   - El subtítulo omite la carrera y el periodo si vienen en `null` (“Mostrar mi carrera” apagado, HU-04); sin carrera queda solo el campus.
   - La unidad del periodo (`cuatrimestre`, `semestre` o `trimestre`) sale de `GET /careers` del campus (`careersProvider`, mismo campus porque la API responde `404` fuera de él). Si esa llamada falla, se muestra el número sin unidad (`9º`), nunca una unidad inventada (RNF-21).
   - No se muestra el correo ni datos privados. Un `404 profiles.not_found` cubre cuenta inexistente, inactiva, de otro campus o con bloqueo en cualquier dirección (HU-57); la pantalla no revela cuál.
2. **Reputación sin calificaciones (RN-26):**
   - Con `stats.ratingAvg == null` la cabecera dice **“Sin calificaciones”** y `ratingCount` es `0`; no se calcula ni se inventa un promedio.
   - Con calificaciones, muestra el promedio con una decimal, la estrella y “N calificaciones”.
   - La pestaña **“Opiniones (0)”** queda vacía con “Todavía no hay opiniones.” y `NOTE (HU-27)` hasta que existan HU-27/HU-45.
3. **Publicaciones activas del perfil (RF-05):**
   - `GET /api/v1/products?sellerId={id}&hideSoldOut=true` devuelve solo las publicaciones `active`, de la más nueva a la más vieja; `total` llena **“Publicaciones (N)”** e `items[]` son las tarjetas.
   - Se reutiliza `ProductPage` y la tarjeta `RecentTile` de la vitrina (foto, título, precio, estado, tiempo); tocar una abre su detalle (HU-11).
   - La API deja fuera agotadas, pausadas, quitadas, vendidas, de otro campus y de personas bloqueadas (HU-57); la app no filtra por su cuenta.
   - Si hay más de una página, “Ver más” pide la siguiente con `nextCursor` y agrega las tarjetas (mismo patrón de `Mis-productos`).
   - Sin publicaciones: “Todavía no tiene publicaciones activas.” con `EmptyView`.
4. **Acceso desde el detalle y el chat (RF-14):**
   - La tarjeta de quien vende en `Producto` abre `Perfil-vendedor` con sesión; sin sesión se queda la hoja “Crea tu cuenta” (HU-48). Si la publicación es mía, abre mi `Perfil`.
   - “Ver perfil” en el menú de `Chat-Valeria` (HU-20) abre el mismo perfil.
   - La ruta es `/vendedor/:id` (`AppRoutes.sellerProfile`) y exige sesión: un enlace directo sin sesión va a `Iniciar-sesion` con `?desde=`.
5. **Estados de la pantalla (RNF-12, RNF-18):**
   - **Cargando:** esqueleto de la cabecera y las tarjetas (nunca una espera muda).
   - **Datos:** cabecera, pestañas y primera página de publicaciones.
   - **Error de red o 5xx:** mensaje en español y “Reintentar”; la cabecera no desaparece si solo fallaron las publicaciones (su error vive dentro de la pestaña).
   - **404:** “No encontramos ese perfil.” y “Regresar”, sin reintento.
6. **Privacidad, campus y bloqueos (RNF-05, RNF-07, RNF-21, OWASP API1/API3):**
   - Solo se pintan los campos del contrato; `sales` se oculta si viene en `null` (“Mostrar mis ventas” apagado).
   - El conteo de publicaciones sale de `total` de la vitrina; no se agrega `activeListings` al perfil ni se duplican datos.
   - Sin endpoint, DTO, esquema ni ruta de API nuevos en la app: se consumen las filas existentes.
7. **Paridad con la maqueta y accesibilidad (RNF-19, RNF-20, RNF-27):**
   - Tokens de `context.musubi`, `MusubiSizes` y `MusubiType`, íconos de `MusubiIcons` y toques de al menos 44 px.
   - Contraste de texto conforme a RNF-20 y layout correcto en un teléfono pequeño y en una tablet.

RNF que aplican: RNF-05 (datos mínimos), RNF-07 (privacidad), RNF-12 (indicador de carga), RNF-18 (mensajes en español), RNF-19 (productos y solicitudes visualmente distintos), RNF-20 (accesibilidad), RNF-21 (campus) y RNF-27 (tamaños).

## Diseño
- **Domain — `lib/features/profile/domain/profile_models.dart`:**
  - `PublicProfile` suma `campusShortName`, `memberSince` y `term` (nullable); conserva `careerShortName`, `ratingAvg`, `ratingCount` y `sales` (nullable).
  - `NOTE (HU-27)` en `ratingAvg`/`ratingCount`: el promedio y las opiniones llegan con HU-27/HU-45.
- **Data — `lib/features/profile/data/http_profile_repository.dart`:**
  - `publicProfile` parsea `campus.shortName`, `memberSince` (UTC), `career.shortName`, `term`, la foto con `mediaUrl` y `stats`.
  - Una forma inesperada se traduce a `ApiFailure` (no un crash); un `DioException` se traduce con `ApiFailure.fromDio`.
- **Data — `lib/features/marketplace/`:**
  - `CatalogRepository` suma `sellerListings(String sellerId, {int page = 1, String? cursor})` → `ProductPage`.
  - `HttpCatalogRepository` llama `GET /api/v1/products` con `sellerId`, `hideSoldOut: true`, `limit: 20` y `page` (o `cursor` en “Ver más”); traduce `DioException` a `ApiFailure`.
  - **Por qué en M-04 y no en M-02:** la ruta es de la vitrina (M-03/M-04) y `ProductPage` ya vive ahí; `ProfileRepository` se queda con M-02 y la pantalla compone las dos lecturas. Así no se duplica el mapeo de productos ni se mete una dependencia de M-03 en M-02.
- **Presentation — estado (`lib/features/profile/presentation/profile_providers.dart`):**
  - `publicProfileProvider` (`FutureProvider.autoDispose.family<PublicProfile, String>`, `retry: null`): se mueve desde `product_screen.dart` y deja de convertir el error en `null`; la tarjeta del vendedor usa `.value` y la pantalla decide por el `ApiFailure`.
  - `sellerListingsProvider` (`FutureProvider.autoDispose.family<ProductPage, String>`, `retry: null`): primera página. La pantalla guarda `_more`, `_moreCursor` y `_loadingMore` para “Ver más”, como `my_products_screen.dart`.
- **Presentation — pantalla nueva `lib/features/profile/presentation/seller_profile_screen.dart`:**
  - `MusubiTopBar` con el nombre y “Regresar”; cabecera con `ProfileAvatar`/`InitialsAvatar`, `VerifiedBadge`, subtítulo, reputación, “En Musubi desde” y ventas.
  - Pestañas de dos opciones con el patrón de `favorites_screen.dart` (`Publicaciones (N)` / `Opiniones (N)`).
  - Publicaciones en `CustomScrollView` + `SliverGrid` de 2 columnas con `RecentTile` (`clockProvider`, `toggleFavorite` y apertura del producto).
  - Opiniones con `EmptyView` y `NOTE (HU-27)`; `NOTE (HU-20)` para “Mensaje” desde el perfil (no se abre aquí).
- **Rutas — `lib/app/router.dart`:** `AppRoutes.seller = '/vendedor'`, `sellerProfile(id)`, la ruta `:id` con `SellerProfileScreen` y la guardia de sesión por prefijo en `sessionRedirect`.
- **Entradas:**
  - `product_screen.dart`: se elimina el `sellerProfileProvider` local y pasa a `onSeller` → `context.push` de la ruta; si `mine`, va a `AppRoutes.profile`.
  - `chat_screen.dart`: `case 'profile'` abre la ruta; el `NOTE (HU-21)` se queda solo para “En línea”.
- **Reutilización:** `ErrorView`, `EmptyView`, `SkeletonShimmer`/`SkeletonBox`, `RecentTile`, `toggleFavorite`, `ProfileAvatar`, `VerifiedBadge` y `monthYear`.
- **Fake-first:** no aplica; los dos endpoints existen. Los fakes de `test/helpers/` se amplían para las pruebas.

## Contratos
- **Fila existente** en [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md), `GET /api/v1/profiles/{id}` (HU-04 · HU-05): `PublicProfileResponse` con `campus`, `memberSince`, `career`, `term` y `stats { ratingAvg, ratingCount, sales }`; sin correo; `ratingAvg: null` y `ratingCount: 0` sin calificaciones (RN-26); `404 profiles.not_found` genérico. La ruta se consume con `ApiPaths.publicProfile` (ya existe).
- **Fila existente**, `GET /api/v1/products` (HU-48 · HU-09 · HU-10 · HU-05): `sellerId` limita a las publicaciones de esa persona y con `hideSoldOut=true` deja solo las activas; `total` es su conteo; `ProductPage { items, nextCursor, total }`; `limit` de 1 a 50 y `page` de 1 a 50. Se consume con `ApiPaths.products` (ya existe); el comentario de `sellerListings` cita la fila.
- **Sin DTOs, rutas, códigos ni fixtures nuevos.** Se reutilizan `profiles.not_found`, `listings.invalid_cursor`, `listings.invalid_page` y `listings.unknown_campus`; la red y el 5xx llegan como `ApiFailure` (`networkError`/`serverError`).
- **Contraparte:** [`musubi-api:HU-05`](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m02-profile/HU-05-perfil-publico).

## Tests
- `test/features/profile/http_profile_repository_test.dart` (+4):
  - `perfil público: mapea campus, carrera, periodo, "desde" y estadísticas` (200 con foto, `memberSince`, `term` y ventas).
  - `perfil público: sin calificaciones ni ventas visibles` (`ratingAvg: null`, `ratingCount: 0`, `sales: null`, carrera oculta).
  - `perfil público: 404 profiles.not_found se traduce a ApiFailure` (código y mensaje en español).
  - `perfil público: una forma inesperada se traduce a ApiFailure` (sin `TypeError`).
- `test/features/profile/seller_profile_providers_test.dart` (+4): datos, error y reintento de `publicProfileProvider` y `sellerListingsProvider`.
- `test/features/marketplace/http_catalog_repository_test.dart` (+4):
  - `publicaciones del vendedor: sellerId, hideSoldOut, limit y page` (query exacta y mapeo de `ProductPage`).
  - `publicaciones del vendedor: "Ver más" manda cursor y no page`.
  - `publicaciones del vendedor: un 400 del back se traduce a ApiFailure` (`listings.invalid_page`).
  - `publicaciones del vendedor: una forma inesperada se traduce a ApiFailure`.
- `test/features/marketplace/demo_catalog_repository_test.dart` (+1): un id estable por vendedor devuelve sus publicaciones activas, sin agotadas.
- `test/features/profile/seller_profile_screen_test.dart` (nuevo, 13):
  - carga (esqueleto), datos de la cabecera, “Sin calificaciones”, publicaciones con “Publicaciones (3)”, sin publicaciones, opiniones vacía, error con “Reintentar” y 404 con “Regresar”.
  - sin `GET /careers`, el periodo se muestra sin unidad (`8º`).
  - si solo fallan las publicaciones, la cabecera sigue y el reintento las carga.
  - “Ver más” agrega la siguiente página.
  - tocar una tarjeta abre el detalle del producto.
  - contraste (RNF-20) y teléfono pequeño/tablet (RNF-27).
- `test/features/marketplace/product_screen_test.dart` (+3): con sesión, la tarjeta abre `/vendedor/{id}`; sin sesión, la hoja “Crea tu cuenta”; mi publicación lleva a `Perfil`.
- `test/features/chat/chat_flow_test.dart` (+1): “Ver perfil” en el menú del chat abre `/vendedor/{id}`.
- `test/app/navigation_test.dart` (+1): `/vendedor/{id}` sin sesión lleva a iniciar sesión con `?desde=`.
- `tool/screenshots_test.dart`: escenas `perfil-vendedor`, `perfil-vendedor-sin-calificaciones` y `perfil-vendedor-vacio` (claro y oscuro), comparadas con la maqueta.
- **Sin `integration_test`:** la navegación se cubre en widget tests con el router real; el flujo en dispositivo se valida a mano al cerrar (no corre en el CI de PR).
- Comandos: `flutter test test/features/profile/ test/features/marketplace/http_catalog_repository_test.dart test/features/marketplace/demo_catalog_repository_test.dart test/features/marketplace/product_screen_test.dart test/features/chat/chat_flow_test.dart test/app/navigation_test.dart`.

## Criterios
- [x] La tarjeta de quien vende en `Producto` abre `Perfil-vendedor` con sesión → `product_screen_test` en verde; sin sesión, la hoja “Crea tu cuenta”; mi publicación lleva a `Perfil`.
- [x] “Ver perfil” del chat abre el mismo perfil → `chat_flow_test` en verde.
- [x] La cabecera muestra foto o iniciales, nombre, `UTTT · carrera · periodo`, “En Musubi desde {mes año}” y ventas → `perfil público: mapea…` y el widget test de datos.
- [x] Sin `GET /careers`, el periodo se muestra sin unidad (`8º`) → widget test.
- [x] Con `ratingAvg: null` dice “Sin calificaciones” y “Opiniones (0)” queda vacía → `perfil público: sin calificaciones…` y widget test.
- [x] “Publicaciones (N)” usa `total` y muestra solo las activas de esa persona → `publicaciones del vendedor: sellerId…` y widget test.
- [x] Sin publicaciones muestra “Todavía no tiene publicaciones activas.” → widget test.
- [x] Un error de red muestra “Reintentar” y vuelve a pedir; un 404 muestra “No encontramos ese perfil.” y “Regresar” → widget tests.
- [x] Mientras carga se ve el esqueleto, y si solo fallan las publicaciones la cabecera sigue y el reintento las carga → widget tests.
- [x] “Ver más” agrega la siguiente página con `nextCursor` → widget test.
- [x] Una forma inesperada del back se traduce a `ApiFailure` (sin `TypeError`) → pruebas de data de perfil y vitrina.
- [x] `dart format --output=none --set-exit-if-changed .` sin cambios · `flutter analyze --fatal-infos --fatal-warnings` 0 · `flutter test` 596/596 · `pwsh scripts/critic-guardrails.ps1` PASS (32 archivos).
- [x] `semgrep scan --config=auto --config=.semgrep/semgrep.yaml --error` sin hallazgos (0 en 110 reglas; la pantalla nueva se escaneó aparte).
- [x] `test/versioning_test.dart` en verde con `0.9.0+11` y la última fila de `docs/versionado.md`.

## Límites
- **“Seguir”:** no está en los criterios de Jira y la API no tiene seguidores; no se muestra.
- **“Responde en”:** la API no mide tiempos de respuesta; no se muestra.
- **“Mensaje” desde el perfil:** la conversación es de HU-20; no se abre desde aquí. `NOTE (HU-20)`.
- **“En línea” / “Activa hace 5 min”:** la API no expone presencia; `NOTE (HU-21)`.
- **Opiniones y promedio:** `ratings`, el cálculo del promedio y la lista de opiniones son de HU-27/HU-45. `NOTE (HU-27)`. La app muestra “Sin calificaciones” con `ratingAvg: null`.
- **Unidad del periodo:** no viene en `PublicProfileResponse`; se toma de `GET /careers` del campus. Si esa llamada falla, se muestra `9º` sin unidad. Si el back agrega `academicTerm` al perfil, se cambia la fuente sin tocar la pantalla.
- **Paginación:** primera página de 20 y “Ver más” con cursor; no hay scroll infinito ni números de página.
- **Mi propio perfil:** si el id es el mío, la pantalla muestra la vista pública (lo que ve el campus); la tarjeta de mi publicación lleva a `Perfil` (HU-04) en lugar de a esta pantalla.
- **Sin datos en vivo:** el perfil y las publicaciones se cargan al abrir; no hay refresco por SignalR ni push.
- **Sin cambios de esquema ni de contrato:** el conteo sale de `total`; no se agrega `activeListings`.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 11-Nov-2026
- **Detalle:**
  - spec escrita desde Jira (SCRUM-34), la maqueta (`Producto`, `Perfil-vendedor`, `Chat-Valeria`) y `musubi-api:HU-05` (`0.5.0-alpha.21`); se aprueba el enfoque A: solo lo que Jira y la API sostienen, sin “Seguir”, “Responde en” ni “Mensaje”.
  - la reputación queda en `null`/`0` hasta HU-27/HU-45, como indicó Jira el 08-Nov-2026; la unidad del periodo se resuelve con `GET /careers` y un fallback sin unidad.
  - T6 (11-Nov-2026): `flutter test` 596/596, `flutter analyze` 0, `dart format` 0, `critic` PASS (32 archivos), `semgrep` 0 hallazgos, `security-reviewer` PASS (se corrigió el parseo tolerante de perfil y vitrina) y `traceability-clerk` OK tras completar pruebas y `NOTE (HU-21)`. Versión `0.9.0+11`; sin revisor designado, no corresponde “Aprobado”.
