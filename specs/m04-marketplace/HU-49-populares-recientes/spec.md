# HU-49 — Ver populares y recién publicados (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-49 / [SCRUM-69](https://uttt-startup-musubi.atlassian.net/browse/SCRUM-69) / Sprint 4 (12-Nov-2026; según comentario Jira) / M-04 / [musubi-api:HU-49](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m04-marketplace/HU-49-populares-recientes)

## Contexto

Como comprador, quiero descubrir productos populares de hoy o de la semana y publicaciones recientes de mi campus. La implementación de HU-49 conecta el selector al ranking HTTP y lleva “Ver todo” a una lista completa con paginación.

La pantalla debe seguir la maqueta `Inicio`, `Recien-publicados` y `Recien-publicados-antiguas`, con los componentes/tokens de `02-04`. **Depende de:** `02-01`, `02-03`, `02-04`, `HU-06`, `HU-10`, `HU-11` y del contrato back de `musubi-api:HU-49`.

## Requisitos

1. Mostrar el selector Hoy/Semana en Inicio y solicitar el periodo seleccionado al repositorio; al cambiar, refrescar el feed sin perder el estado de carga/error manejado por Inicio.
2. Mostrar Populares con orden y datos de vistas proporcionados por la API; no fabricar el ranking en producción. Si está vacío, mostrar estado vacío previsto por la maqueta sin ocultar las demás secciones de Inicio.
3. Abrir “Ver todo” de Publicaciones recientes en una pantalla dedicada, no en Búsqueda. Mostrar solo productos disponibles, del más nuevo al más antiguo, y ofrecer “Más antiguas” cuando haya cursor.
4. Cargar páginas de forma incremental sin duplicar productos; mantener los productos ya cargados si falla una página posterior y permitir reintentarla. Un fallo de la primera página muestra error y acción Reintentar.
5. Abrir el detalle al tocar una tarjeta y conservar navegación de regreso. La lista usa el repositorio/provider y cliente de API existentes; UI no llama Dio.
6. Mantener la política de privacidad de la respuesta de producto; no guardar localmente historial de vistas ni datos de quien consulta.

RNF aplicables: RNF-05/RNF-07 (privacidad), RNF-21 (campus), RNF-23 (arquitectura modular) y RNF-27 (áreas táctiles según política de la app).

## Diseño

- **Feature:** `lib/features/marketplace/` (domain/data/presentation); sin feature paralela.
- **Inicio:** extender `HttpCatalogRepository.homeFeed` para consultar la ruta de populares del back y mapear `views`/producto al modelo existente. El endpoint acordado es `GET /api/v1/products/popular?period=today|week`; su forma JSON se enlaza en la spec back y no se copia aquí.
- **Recientes:** agregar método de repositorio que consulte `GET /api/v1/products?sort=newest|oldest&hideSoldOut=true&limit=20&cursor=...`; conservar el cursor opaco de API y validar `nextCursor == null` para finalizar. La fila canónica y sus parámetros viven en [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md).
- **Estado:** provider Riverpod para página/continuación con `retry: (_, _) => null`, prevención de carga concurrente y protección contra duplicados por `ProductSummary.id`; conservar datos previos ante error de página siguiente.
- **UI:** ruta pública `AppRoutes.recentProducts`; pantalla con título “Recién publicados”, mosaico de tarjetas existentes, acción “Más antiguas”, estados de carga/vacío/error y navegación al detalle. `SeeAllNewCard` y botón “Ver todo” apuntan a esta ruta.
- **Fake:** `FakeCatalogRepository` ofrece respuestas por páginas y ranking para widget tests. No usar rankings demo en el repositorio HTTP de producción.
- **Coordinación:** decisión del usuario: cada apertura válida cuenta (incluidas anónimas y repetidas), excepto la del vendedor; Hoy es el día UTC actual y Semana son los últimos 7 días UTC. El contrato de ranking queda enlazado a la spec API.

## Contratos

- **Vitrina existente:** enlazar `GET /api/v1/products` en [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) (fila de M-03/HU-48/HU-09/HU-10), con `sort`, `hideSoldOut`, `limit`, `cursor`; respuesta `ProductPage { items, nextCursor, total }`.
- **Ranking:** enlazar la fila de `GET /api/v1/products/popular?period=today|week&campus=&cursor=&limit=` en la spec API de HU-49. Respuesta `PopularProductPage { items: [{ product: ProductResponse, views }], nextCursor, total }`; la forma y fixture son propiedad de la spec API, no se duplican aquí.
- **Detalle:** fila existente `GET /api/v1/products/{id}` (HU-11); abre con preview opcional.
- **Rutas:** `ApiPaths.popularProducts` apunta a la fila canónica de la API; la ruta de recientes reutiliza `ApiPaths.products`.

## Tests

- `test/features/marketplace/data/http_catalog_repository_test.dart`: periodos Hoy/Semana; mapeo de ranking y `views`; orden/parametría de recientes, cursor, `hideSoldOut` y conversión de errores Dio a `ApiFailure`.
- `test/features/marketplace/recent_products_provider_test.dart`: continuación por cursor y deduplicación. Añadir pruebas de pantalla/carga/error antes del cierre.
- `test/features/marketplace/home_screen_test.dart`: selector cambia el periodo; populares vacíos no eliminan recientes/“Se busca”; “Ver todo” abre la ruta de recientes.
- `test/app/navigation_test.dart`: ruta pública y regreso desde detalle.
- Capturas con `tool/screenshots_test.dart` para Inicio y `Recien-publicados` en claro/oscuro, comparadas con la maqueta.

## Criterios

- [ ] Cambiar Hoy/Semana solicita el periodo elegido y muestra solo el ranking devuelto por API → repository test y `home_screen_test.dart`.
- [ ] El estado vacío de Populares no bloquea el resto de Inicio → widget test.
- [ ] “Ver todo” abre la lista dedicada; la primera página muestra disponibles de más nuevo a más antiguo → widget y repository tests.
- [ ] “Más antiguas” pide cursor siguiente una vez, agrega sin duplicados y desaparece al terminar → `recent_products_test.dart`.
- [ ] Error inicial ofrece reintento; error de continuación conserva la lista y permite reintentar → `recent_products_test.dart`.
- [ ] `dart format --output=none --set-exit-if-changed .` sin cambios, `flutter analyze --fatal-infos --fatal-warnings` sin observaciones, `flutter test` 100 % y `pwsh scripts/critic-guardrails.ps1` PASS.
- [ ] Capturas de Inicio y recientes se comparan con la maqueta; validar la navegación en dispositivo/emulador antes del cierre.

## Límites

- El ranking real depende del endpoint de `musubi-api:HU-49`; la app no contará ni deduplicará vistas localmente.
- No se añaden reglas de conteo del lado app; la API aplica la semántica aprobada.
- No se añade caché local/offline; HU-53 confirmó que la API es fuente de verdad para su alcance, y esta HU no requiere persistencia local.
- No se cambia la búsqueda ni sus filtros; “Ver todo” deja de redirigir a Búsqueda.

## Aprobación y Control de Cambios

- **Estado:** 🚧 Borrador
- **Revisores:** Pendiente de designar (1 revisor distinto del autor)
- **Fecha:** 12-Nov-2026
- **Detalle:** Implementación de recientes y ranking conectada al contrato API de HU-49. El usuario definió vistas anónimas/repetidas y periodo UTC. La suite completa Flutter y pruebas de widgets/navegación/capturas no se pudieron verificar en este entorno: Dart 3.12.2, mientras `pubspec.yaml` requiere ^3.13.5. Mantener Borrador hasta tener evidencia y revisor.
