# Plan — HU-49 Ver populares y recién publicados (app)

## Componentes

- `lib/core/network/api_paths.dart`: constante de ranking al confirmar contrato back; recientes conserva `ApiPaths.products`.
- `lib/features/marketplace/domain/catalog_repository.dart`: métodos para ranking (o ampliar `homeFeed`) y consultar página reciente con cursor.
- `lib/features/marketplace/domain/home_feed.dart`: reaprovechar `ProductSummary.views`, `PopularPeriod`, `ProductPage`.
- `lib/features/marketplace/data/http_catalog_repository.dart`: consultas HTTP y mapeo de ranking/continuación; sin Dio en presentation.
- `lib/features/marketplace/presentation/home_providers.dart`: reaccionar al periodo elegido y cargar ranking desde backend.
- `lib/features/marketplace/presentation/recent_products_screen.dart` y provider dedicado: paginación y estados.
- `lib/app/router.dart`, `home_screen.dart` y tarjeta “Ver todo”: ruta y navegación.
- `test/features/marketplace/{data/http_catalog_repository_test.dart,recent_products_test.dart,home_screen_test.dart}` y `test/app/navigation_test.dart`; extender fake de `test/helpers/fake_catalog_repository.dart`.
- Capturas en `tool/screenshots_test.dart` con fixtures existentes de maqueta.

## Decisiones

1. Reutilizar feature, repositorio, modelos, tarjetas y navegación actuales; no duplicar catálogo ni usar Búsqueda para representar “todos los recientes”.
2. Recientes se carga con `sort=newest`, `hideSoldOut=true`, `limit=20` y cursor opaco de la API. “Más antiguas” solicita la siguiente página; no usa `page`/`skip` ni ordenamiento local.
3. La vista guarda elementos previos si falla una página posterior; evita doble petición concurrente y deduplica por id.
4. Popular usa el endpoint real de la contraparte una vez que la fila canónica/contrato exista. No mostrar fixtures demo en producción ni inventar `views` del lado app.
5. **Decisión de contrato (12-Nov-2026):** cada apertura válida cuenta, incluidas anónimas y repetidas, salvo vendedor. Hoy es día UTC actual y Semana los últimos siete días UTC.

## Guardarraíles

- Publicación/campus/estado los determina el servidor; no inferir disponibilidad solo con filtro visual.
- Errores de red se traducen a `ApiFailure`; no filtrar `DioException` ni PII a UI/logs.
- La ruta es pública, permite visitante y respeta token/campus según el servidor; nada requiere sesión.
- El provider evita retry automático de Riverpod y deja el reintento explícito visible.
- No persistir ranking ni historial en almacenamiento local.
- Respetar patrones visuales, tokens `context.musubi`/`MusubiSizes`, `Pressable` y accesibilidad táctil de la app.

## Validación

- TDD en repository, provider/widget y navegación; fixtures deterministas, sin esperas arbitrarias.
- `dart format --output=none --set-exit-if-changed .`
- `flutter analyze --fatal-infos --fatal-warnings`
- `flutter test`
- `pwsh scripts/critic-guardrails.ps1`
- Capturas de Inicio y Recien-publicados en ambos temas; smoke test Android con API compatible cuando el endpoint back esté desplegado/local.
- No fijar latencia/timeout/TTL de cliente nuevos sin medición.

## Secuencia

1. Confirmar que el contrato exacto de populares coincide con la spec API y enlazar la fila canónica.
2. Implementar página de recientes y cursor sobre ruta ya existente, con fake paginado y pruebas.
3. Cambiar “Ver todo” a ruta dedicada y agregar widget tests/capturas.
4. Con API disponible, mapear ranking al modelo `ProductSummary` y conectar selector con pruebas de ambos periodos.
5. Correr formato, analyze, suite completa y critic; actualizar trazabilidad/Memoria y conciliar con spec back.
6. Mantener “Borrador con evidencia” hasta que el PR esté verde; aprobación solo con revisor elegido por usuario.
