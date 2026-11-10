# plan.md — HU-53 Guardar productos en favoritos (app)

## 1. Componentes

**Nuevos**
- `lib/features/marketplace/domain/favorite_models.dart`
- `lib/features/marketplace/domain/favorites_repository.dart`
- `lib/features/marketplace/data/http_favorites_repository.dart`
- `lib/features/marketplace/presentation/favorites_providers.dart`
- `lib/features/marketplace/presentation/favorites_actions.dart`
- `lib/features/marketplace/presentation/favorites_screen.dart`
- `test/features/marketplace/data/http_favorites_repository_test.dart`
- `test/features/marketplace/favorites_providers_test.dart`
- `test/features/marketplace/favorites_screen_test.dart`
- `test/helpers/fake_favorites_repository.dart`

**Cambian**
- `lib/core/network/api_paths.dart`: `favorites` y `favorite(productId)`, citando las filas 79–81.
- `lib/features/marketplace/presentation/home_cards.dart`: `SaveButton` con estado y `onSave` por producto.
- `lib/features/marketplace/presentation/home_screen.dart`: corazón de Inicio.
- `lib/features/marketplace/presentation/search_screen.dart`: corazón de Búsqueda.
- `lib/features/marketplace/presentation/product_screen.dart`: corazón del detalle.
- `lib/features/profile/presentation/profile_screen.dart`: mosaico "Favoritos".
- `lib/app/router.dart`: `/favoritos` en la rama de Perfil y en `requiresSession`.
- `test/features/marketplace/home_screen_test.dart`, `search_screen_test.dart`, `product_screen_test.dart` y `test/features/profile/profile_flow_test.dart`: overrides del repositorio de favoritos y casos nuevos.
- `tool/screenshots_test.dart`: escena `favoritos`.
- `docs/trazabilidad.md` y `Memoria.md`: al cerrar.

## 2. Decisiones

- **Enfoque B, sin tocar productos.** `GET /favorites` devuelve la lista y un `Set` de ids; el corazón consulta ese set. Así la vitrina pública conserva su caché y el back no agrega una consulta de favoritos a cada página. Es la decisión ya tomada en `musubi-api:HU-53`.
- **Un estado global por sesión.** `favoritesProvider` escucha el `userId` de `sessionControllerProvider`, no el token completo: una renovación de sesión no vuelve a pedir la lista. Al cerrar sesión devuelve vacío; al entrar con otra cuenta recarga. La app no persiste nada (RNF-07).
- **Sin fake de endpoint.** Las filas del back existen en local; el repositorio real se prueba con `FakeHttpAdapter`. El `fake_favorites_repository.dart` es solo para pruebas y capturas, no sustituye al endpoint.
- **El corazón cambia al confirmar la API.** No se pinta un estado optimista: si el `PUT`/`DELETE` falla, el corazón anterior sigue siendo verdad y se muestra el error. Dos toques seguidos se ignoran por producto mientras hay una petición en vuelo.
- **Agregar no vuelve a pedir la lista.** El controlador construye el `FavoriteItem` con el `ProductSummary` que ya tiene la pantalla y la hora del `clockProvider`; `DELETE` quita el id. El siguiente `GET` (al volver a abrir sesión) reconcilia con el servidor.
- **Tabs con proveedor pequeño.** `favoriteTabProvider` conserva la pestaña elegida al salir y volver, como `APP.ui.favTab` de la maqueta.
- **"Agotados" incluye `soldOut` y `unavailable`.** La maqueta usa una sola pestaña para lo que ya no se puede comprar; el texto de cada tarjeta distingue "Agotado" de "Ya no está disponible".
- **Aviso con "Ver"/"Deshacer".** Se conserva la interacción de la maqueta: guardar ofrece "Ver" y quitar ofrece "Deshacer". "Deshacer" vuelve a llamar a `PUT`; para un `unavailable` sin producto no se ofrece, porque el back respondería 404.
- **Sin modo sin conexión ni caché local.** Decisión de Jira del 08-Nov-2026 y límite del back. No se agrega SQLite; 02-01 y 02-06 se concilian para dejar la caché local fuera del MVP.
- **Versión.** No se cambia `pubspec.yaml` en este PR: `0.6.0+8` ya está usada en Play y el siguiente lote define el número y su fila en `docs/versionado.md`; no se fija un `versionCode` nuevo aquí.

## 3. Excepciones al stack

Ninguna. Se usan Flutter, Riverpod 3, go_router, Dio y los widgets existentes de `lib/core/widgets/`; no se agrega un paquete.

## 4. Guardarraíles

- **Seguridad:** el token solo viaja por `dioProvider`/`AuthInterceptor` hacia la API; la UI nunca importa `dio`. Las rutas no llevan el id del usuario: la API decide por el token (OWASP API1).
- **Privacidad:** el proveedor se limpia al cerrar sesión y se recarga por `userId`; no se escriben favoritos en disco ni se muestran datos de otras cuentas. La app no cuenta cuántas personas guardaron un producto.
- **Errores:** `ApiFailure.fromDio` traduce 401, 403, 404, 5xx y red; ningún `DioException` llega a la UI. Un elemento inválido de la respuesta se descarta o se vuelve `unavailable`; no tumba la lista.
- **Estados:** cargando, datos, vacío y error con reintento; el corazón no queda "guardado" si la API falló. Textos en español.
- **Accesibilidad y tamaños:** etiqueta semántica "Guardar"/"Quitar de favoritos", área táctil de 44, contraste AA y sin overflow de 360×640 a tablet.
- **Límite conocido:** máximo 200 favoritos sin paginar; se documenta con `NOTE (HU-53)` en el proveedor o la pantalla.

## 5. Validación

- `dart format --output=none --set-exit-if-changed .`
- `flutter analyze --fatal-infos --fatal-warnings`
- `flutter test` (conteo real al cerrar)
- `pwsh scripts/critic-guardrails.ps1`
- `semgrep scan --config=auto --config=.semgrep/semgrep.yaml --error`
- `flutter test tool/screenshots_test.dart --dart-define=SHOTS=<carpeta> --dart-define=ONLY=favoritos` (claro y oscuro)
- Prueba manual en emulador contra la API local (`config/dev.json`, `http://10.0.2.2:5080`) y, si está desplegada, contra AWS.
- Antes del PR: `security-reviewer` y `traceability-clerk`; el PR enlaza `musubi-api:HU-53` y usa la clave `SCRUM-68`.

## 6. Secuencia de implementación

1. **T1 · Specs.** Cerrar `spec.md`, `plan.md` y `task.md`; conciliar las specs que atribuían datos locales a HU-53 (`02-01`, `02-04`, `02-06`, HU-06, HU-09, HU-10, HU-11, HU-13 y HU-50).
2. **T2 · Dominio y datos.** Crear modelos, interfaz, `ApiPaths`, repositorio HTTP y sus pruebas con `FakeHttpAdapter`.
3. **T3 · Estado.** `favoritesRepositoryProvider`, `favoritesProvider`, `favoriteTabProvider`, fake de pruebas y pruebas de provider/sesión.
4. **T4 · Corazones.** Helper de aviso, `SaveButton` con estado, tarjetas de Inicio/Búsqueda y corazón del detalle; ajustar pruebas existentes.
5. **T5 · Pantalla.** `FavoritesScreen`, tarjeta de los tres estados, tabs, ruta `/favoritos`, mosaico de Perfil y pruebas de widget.
6. **T6 · Evidencia.** Captura `favoritos` claro/oscuro, accesibilidad/tamaños, `docs/trazabilidad.md`, `Memoria.md`, `security-reviewer` y `traceability-clerk`.

## 7. Riesgos y dependencias

- La app no debe publicarse antes de la API `0.5.0-alpha.13` (esquema 13).
- `ProductResponse` no trae la calificación del vendedor; la tarjeta de Favoritos muestra solo el nombre. Es una diferencia aceptada con la maqueta.
- El tope de 200 y la ausencia de paginación son límites del back; si se superan, se pagina en otra HU.
- El aviso "Deshacer" hace una llamada extra a `PUT`; si la publicación dejó de ser visible, el back responde 404 y se muestra el mensaje, sin dejar el corazón en un estado falso.
