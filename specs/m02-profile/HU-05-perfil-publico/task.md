# HU-05 — Consultar perfil y reputación de otro usuario (app, tareas)

## T1 — Detallar la spec
- **Qué:** conciliar Jira (SCRUM-34), la maqueta (`Producto`, `Perfil-vendedor`, `Chat-Valeria`) y las filas de `musubi-api:HU-05`; resolver las decisiones de alcance.
- **Resultado:** `spec.md` y `plan.md` completos; enfoque A aprobado (sin “Seguir”, “Responde en” ni “Mensaje”); contratos enlazados a `endpoints.md` (filas `GET /profiles/{id}` y `GET /products`).
- **Estado:** ✅ Hecho (11-Nov-2026).

## T2 — Dominio y datos
- **Qué:**
  - `PublicProfile` con `campusShortName`, `memberSince` y `term`;
  - parseo en `HttpProfileRepository.publicProfile`;
  - `CatalogRepository.sellerListings(String sellerId, {int page = 1, String? cursor})` y `HttpCatalogRepository` con `sellerId`, `hideSoldOut: true`, `limit: 20`, `page` o `cursor`;
  - `DemoCatalogRepository.sellerListings` y `FakeCatalogRepository` ampliados.
- **Verificar:** `test/features/profile/http_profile_repository_test.dart` (+3), `test/features/marketplace/http_catalog_repository_test.dart` (+2) y `demo_catalog_repository_test.dart` (+1); `flutter test` 571/571, `flutter analyze` 0.
- **Estado:** ✅ Hecho (11-Nov-2026).

## T3 — Estado
- **Qué:**
  - `publicProfileProvider` compartido en `profile_providers.dart` (sin tragarse el error) y `product_screen.dart` usando `.value`;
  - `sellerListingsProvider` para la primera página;
  - `FakeProfileRepository.failPublicProfile` y `FakeCatalogRepository.failSellerListings` para los estados de error.
- **Verificar:** `test/features/profile/seller_profile_providers_test.dart` (4: datos, error y reintento de cada provider); `flutter test` 575/575, `flutter analyze` 0.
- **Estado:** ✅ Hecho (11-Nov-2026).

## T4 — Pantalla, ruta y entradas
- **Qué:**
  - `seller_profile_screen.dart` (cabecera, pestañas, publicaciones con “Ver más” por cursor, opiniones vacía, estados de carga/error/404);
  - `AppRoutes.seller`, `sellerProfile(id)`, ruta `/vendedor/:id` y guardia de sesión;
  - tarjeta del vendedor en `Producto` (mi publicación lleva a `Perfil`) y “Ver perfil” en `Chat-Valeria`;
  - `NOTE (HU-20)` en la pantalla y `NOTE (HU-27)` en opiniones; `MusubiTopBar` recorta nombres largos.
- **Verificar:** `test/features/profile/seller_profile_screen_test.dart` (13), `product_screen_test.dart` (+3), `chat_flow_test.dart` (+1), `navigation_test.dart` (+1) y `http_catalog_repository_test.dart` (+1 por cursor); `flutter test` 591/591 al cerrar T4, `flutter analyze` 0.
- **Estado:** ✅ Hecho (11-Nov-2026).

## T5 — Evidencia y documentación
- **Qué:**
  - escenas `perfil-vendedor`, `perfil-vendedor-sin-calificaciones` y `perfil-vendedor-vacio` en `tool/screenshots_test.dart` (claro y oscuro);
  - contraste RNF-20 y tamaños RNF-27 (cubiertos en T4);
  - `docs/trazabilidad.md` (tests y estado técnico);
  - `Memoria.md`;
  - versión `0.9.0+11` en `pubspec.yaml`, `lib/app/app_version.dart` y la fila de la app en `docs/versionado.md`.
- **Verificar:** 3 escenas claras y 3 oscuras generadas; `test/versioning_test.dart` 3/3; `flutter test` 591/591 al cerrar T5.
- **Estado:** ✅ Hecho (11-Nov-2026).

## T6 — Gates
- **Qué:** `dart format`, `flutter analyze`, `flutter test`, `pwsh scripts/critic-guardrails.ps1`, `semgrep`, `security-reviewer` y `traceability-clerk`; dejar la spec en “🚧 Borrador con evidencia” con los conteos reales.
- **Resultado:** `dart format` 0 · `flutter analyze --fatal-infos --fatal-warnings` 0 · `flutter test` 596/596 · `test/versioning_test.dart` 3/3 · `critic` PASS (32 archivos) · `semgrep` 0 hallazgos (110 reglas; la pantalla nueva se escaneó aparte) · `security-reviewer` PASS tras corregir el parseo tolerante de perfil y vitrina · `traceability-clerk` OK tras añadir las pruebas de visitante, mi perfil, fallback de `careers`, `NOTE (HU-21)` y el estado “Borrador con evidencia”.
- **Estado:** ✅ Hecho (11-Nov-2026).

## Pendientes
- `NOTE (HU-27)`: promedio, calificaciones y lista de opiniones (HU-27/HU-45); la pestaña “Opiniones (0)” queda vacía.
- `NOTE (HU-20)`: “Mensaje” desde el perfil no se abre en esta HU; la conversación es de HU-20.
- **Unidad del periodo:** si la API agrega `academicTerm` a `PublicProfileResponse`, cambiar la fuente de `careersProvider` a ese campo.
- **Paginación:** “Ver más” con cursor; si alguien supera 20 publicaciones activas, medir si conviene scroll infinito.
