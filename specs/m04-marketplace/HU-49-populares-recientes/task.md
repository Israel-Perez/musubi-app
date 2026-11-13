# HU-49 — Ver populares y recién publicados (app)

## T1 — Detallar spec y contrato
- **Qué:** conciliar rutas/DTO con `musubi-api:HU-49`; conservar aperturas de vista, exclusión de vendedor, definir anónimos/repetidas y fronteras de periodo.
- **Verificación:** fila API enlazada y decisiones iguales en ambas specs.
- **Estado:** ✅ Decisiones de uso/periodo confirmadas; contrato API definido en spec back.

## T2 — Repositorio y paginación de recientes
- **Qué:** implementar método cursor de recientes y fake paginado.
- **Archivos:** `catalog_repository.dart`, `http_catalog_repository.dart`, `fake_catalog_repository.dart`.
- **Verificación:** pruebas HTTP validan `sort=newest`, `hideSoldOut`, `limit`, cursor, respuesta vacía y errores.
- **Estado:** 🟡 Implementado; pruebas no reejecutables en este worktree por Dart SDK incompatible.

## T3 — Pantalla y ruta de recientes
- **Qué:** crear pantalla completa, estados, “Más antiguas”, ruta pública; cambiar “Ver todo” que hoy abre Búsqueda.
- **Archivos:** `recent_products_screen.dart`, provider dedicado, `router.dart`, `home_screen.dart` y tests.
- **Verificación:** primera página, continuación, fin, deduplicación, errores/reintento y regreso del detalle.
- **Estado:** 🟡 Pantalla/ruta y acción “Ver todo” implementadas; widget tests, capturas y comprobación con API real pendientes.

## T4 — Ranking real en Inicio
- **Qué:** conectar Hoy/Semana al endpoint popular y mapear la respuesta.
- **Archivos:** `api_paths.dart`, `http_catalog_repository.dart`, provider/feed y tests/capturas.
- **Verificación:** Hoy y Semana envían el parámetro correcto y muestran exactamente el orden/elementos recibidos.
- **Decisión:** cada apertura válida cuenta, incluida anónima/repetida excepto vendedor; UTC hoy y últimos 7 días.
- **Estado:** 🟡 Implementado contra el contrato de HU-49 en la rama API; pruebas del repositorio HomeFeed/capturas pendientes.

## T5 — Evidencia y trazabilidad
- **Qué:** capturas de Inicio/Recien-publicados en claro/oscuro, actualizar `docs/trazabilidad.md` y `Memoria.md`.
- **Verificación:** format sin cambios, analyze limpio, `flutter test` verde, critic PASS y smoke test.
- **Estado:** ⏳ Pendiente: Flutter 3.12.2 no satisface el mínimo ^3.13.5; ejecutar format/analyze/flutter test y capturas con SDK compatible.
