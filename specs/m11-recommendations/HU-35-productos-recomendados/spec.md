# HU-35 — Ver productos recomendados (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-35 / SCRUM-58 / Sprint 5 (14 nov – 1 dic 2026) / M-11 / [musubi-api:HU-35](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m11-recommendations/HU-35-productos-recomendados)

## Contexto
Jira (SCRUM-58): Como **comprador**, quiero **ver productos recomendados según mis intereses**, para **descubrir artículos que me pueden servir**.

- Maqueta: `Inicio` (título "Recomendado para ti" de la guía de estilo) y `Producto` / `Producto-visitante` ("Ver parecidos").
- Trazabilidad: RF-48, RF-49 · CU-21 · RN-45, RN-46 · RNF-07 · lineamiento **L-16i** (el modelo de ML vive en la API).
- Decisiones de la usuaria (13-Nov-2026): en `Inicio` y en `Producto`; señales ver, favorito, chat y compra; 90 días.

**Depende de:** [musubi-api:HU-35](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m11-recommendations/HU-35-productos-recomendados), `HU-11`, `HU-47` (aviso de privacidad) y `HU-54` (preferencias).

## Requisitos
1. **R1 · Recomendado para ti:** en `Inicio`, con sesión, entre "Se busca" y "Publicaciones recientes", una fila horizontal con las tarjetas de "Publicaciones recientes". Cargando, con error o vacía, no se muestra.
2. **R2 · Productos parecidos:** al final de `Producto` (con o sin sesión); tocar uno abre su detalle.
3. **R3 · Ver parecidos:** en una agotada, el botón baja hasta la sección; si no hay parecidos, "Aún no encontramos productos parecidos.".
4. **R4 · Se puede rechazar:** en `Privacidad` → "Tus datos", "Recomendaciones según tu actividad" (encendido por defecto). Apagarlo avisa que se borró el historial; si falla, regresa y lo explica.
5. **R5 · Aviso de privacidad:** dice qué se guarda (90 días) y dónde se apaga.

## Diseño
- `lib/features/recommendations/` (dominio, `HttpRecommendationRepository`, providers); `ApiPaths.recommendations` y `ApiPaths.productSimilar`.
- `HomeScreen._ForYouSection` y `ProductScreen._SimilarSection` con `RecentTile`.
- `ThemePreferenceRepository.getRecommendations` / `setRecommendations` y `recommendationsPreferenceProvider`.

## Contratos
Filas `GET /api/v1/recommendations`, `GET /api/v1/products/{id}/similar` y las de `/profiles/me/preferences` (`recommendations`) de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md).

## Tests
- `test/features/recommendations/recommendation_data_test.dart`: rutas, límite, lectura y errores.
- `test/features/marketplace/home_screen_test.dart`: la sección con sesión, oculta si falla o está vacía, y el visitante no la pide.
- `test/features/marketplace/product_screen_test.dart`: la sección, abrir una parecida, "Ver parecidos" baja y sin parecidos avisa.
- `test/features/profile/profile_flow_test.dart` y `http_theme_preference_repository_test.dart`: el interruptor (con el tema actual) y su falla.
- Capturas `inicio-para-ti` y `producto-parecidos`.

## Criterios
- [x] Se muestran recomendaciones en `Inicio` y parecidos en `Producto` → pruebas de widget y capturas.
- [x] Sin datos no se rompe nada → secciones ocultas con error o vacías.
- [x] Se puede rechazar desde la app → `profile_flow_test.dart`.
- [x] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` 665 al 100 % · critic PASS.

## Límites
- Las recomendaciones salen de la API (ML.NET); la app solo las muestra.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026 (borrador ligero) · 14-Nov-2026 (detallado e implementado)
- **Detalle:** con las decisiones de la usuaria del 13-Nov-2026.
