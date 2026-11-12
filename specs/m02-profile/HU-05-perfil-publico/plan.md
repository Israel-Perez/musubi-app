# plan.md — HU-05 Consultar perfil y reputación de otro usuario (app)

1. **Componentes:**
   - `lib/features/profile/domain/profile_models.dart` (`PublicProfile` con `campusShortName`, `memberSince` y `term`);
   - `lib/features/profile/data/http_profile_repository.dart` (parseo de la cabecera pública);
   - `lib/features/marketplace/domain/catalog_repository.dart` (`sellerListings`) y `lib/features/marketplace/data/http_catalog_repository.dart` (`GET /products?sellerId=&hideSoldOut=true`);
   - `lib/features/profile/presentation/profile_providers.dart` (`publicProfileProvider` compartido y `sellerListingsProvider`);
   - `lib/features/profile/presentation/seller_profile_screen.dart` (nuevo);
   - `lib/app/router.dart` (`AppRoutes.seller`, `sellerProfile(id)`, ruta `/vendedor/:id` y guardia de sesión);
   - `lib/features/marketplace/presentation/product_screen.dart` (quitar el provider local y abrir la ruta) y `lib/features/chat/presentation/chat_screen.dart` (“Ver perfil”);
   - pruebas (`test/features/profile/`, `test/features/marketplace/`, `test/features/chat/`), `test/helpers/fake_profile_repository.dart`, `test/helpers/fake_catalog_repository.dart` y `tool/screenshots_test.dart`.
2. **Decisiones:**
   - **`sellerListings` vive en `CatalogRepository` (M-04), no en `ProfileRepository`:** la ruta es de la vitrina y `ProductPage` ya está ahí; M-02 se queda con el perfil y la pantalla compone las dos lecturas. Evita duplicar el mapeo de productos y meter una dependencia de M-03 en M-02.
   - **Un solo `publicProfileProvider`:** se mueve de `product_screen.dart` a `profile_providers.dart` y deja de convertir el error en `null`; la tarjeta usa `.value` y la pantalla recibe el `ApiFailure` para decidir entre “Reintentar” y “No encontramos ese perfil”.
   - **La cabecera trae el campus, no solo el nombre:** la decisión de Jira (08-Nov-2026) lo incluye y es lo que distingue a dos personas del mismo campus.
   - **Unidad del periodo desde `careersProvider`:** `PublicProfileResponse` no trae `academicTerm`; `GET /careers` sí y es del mismo campus (la API responde 404 fuera de él). Si falla, se muestra `9º` sin unidad: no se inventa “cuatrimestre” (RNF-21).
   - **“Ver más” con cursor, como `Mis-productos`:** estado local (`_more`, `_moreCursor`, `_loadingMore`), sin scroll infinito ni provider de paginación nuevo.
   - **El 404 no se reintenta:** “No encontramos ese perfil.” y “Regresar”; un error de red o 5xx sí ofrece “Reintentar”. El error de publicaciones vive dentro de la pestaña para no tumbar la cabecera.
   - **La tarjeta de mi propia publicación lleva a `Perfil` (HU-04):** ver mi vista pública desde ahí no aporta y evita una pantalla duplicada de mí mismo.
   - **Fuera de alcance por decisión A:** “Seguir”, “Responde en” y “Mensaje” (HU-20). Se declaran en `Límites`; no se dejan botones muertos.
   - **Sin fake-first:** los dos endpoints existen en `musubi-api:HU-05`; solo se amplían los fakes de prueba.
3. **Excepciones al stack (00-01):** ninguna. No se agregan paquetes.
4. **Guardarraíles:**
   - la UI no importa `dio`; pantalla → provider → interfaz del repositorio;
   - toda excepción de red se traduce a `ApiFailure` con mensaje en español (RNF-18);
   - no se pinta el correo ni campos fuera del contrato (RNF-05, RNF-07);
   - `/vendedor/:id` exige sesión; el enlace directo sin sesión va a `Iniciar-sesion` con `?desde=`;
   - sin `http://` en `lib/`, sin `print`, sin `TODO`; los pendientes usan `NOTE (ID)` (`HU-20`, `HU-27`);
   - toques de 44 px y contraste RNF-20; teléfono pequeño y tablet RNF-27.
5. **Validación:**
   - pruebas de `spec.md` → `http_profile_repository_test.dart`, `http_catalog_repository_test.dart`, `seller_profile_screen_test.dart`, `product_screen_test.dart` y `chat_flow_test.dart`;
   - capturas `perfil-vendedor*` con `flutter test tool/screenshots_test.dart --dart-define=SHOTS=<carpeta>` (claro y oscuro);
   - `dart format --output=none --set-exit-if-changed .`, `flutter analyze --fatal-infos --fatal-warnings`, `flutter test`, `pwsh scripts/critic-guardrails.ps1` y `semgrep scan --config=auto --config=.semgrep/semgrep.yaml --error`;
   - `security-reviewer` y `traceability-clerk` antes del PR.
6. **Secuencia:**
   - T1: conciliar la spec con la API y la maqueta (hecho);
   - T2: dominio y datos (modelo, parseo, `sellerListings`, fakes y pruebas);
   - T3: providers (`publicProfileProvider`, `sellerListingsProvider`) y sus pruebas;
   - T4: pantalla, ruta y entradas desde producto y chat, con widget tests;
   - T5: capturas, accesibilidad/tamaños, `docs/trazabilidad.md`, `Memoria.md` y versión;
   - T6: format, analyze, tests, critic, semgrep, `security-reviewer` y `traceability-clerk`.
