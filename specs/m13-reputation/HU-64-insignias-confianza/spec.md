# HU-64 — Ver insignias de confianza de quien vende (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-64 / SCRUM-104 / Sprint 5 (14 nov – 1 dic 2026) / M-13 / [musubi-api:HU-64](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m13-reputation/HU-64-insignias-confianza)

## Contexto
Jira (SCRUM-104): Como **comprador**, quiero **ver insignias de confianza de quien vende**, para **saber rápido si es alguien con quien conviene tratar**.

- Maqueta: `Producto` (tarjeta de quien vende: "Responde en ~1 h") y `Perfil-vendedor` (chips "Responde en ~1 h" y "En Musubi desde"). "Vendedor confiable" no está: se arma con sus piezas (lineamiento 4).
- Trazabilidad: RF-36. Origen: ideas del 13-Nov-2026.
- **Decisiones de la usuaria (16-Nov-2026):** 4.5 ★ con 5 ventas; la mediana con al menos 3 respuestas en 30 días; en `Producto` y `Perfil-vendedor` (no en las tarjetas).

**Depende de:** `HU-05` (`Perfil-vendedor`), `HU-11` (`Producto`), `02-04` (piezas de la maqueta).

## Requisitos
1. **R1 · Leer:** `PublicProfile.responseMinutes` y `PublicProfile.trusted` de `GET /profiles/{id}` (las calcula la API).
2. **R2 · "Responde en ~N":** redondeo de la maqueta (`approxDuration`: ~15, ~30 y ~45 min, ~1 h, ~N h, ~N días) en la tarjeta de `Producto` (12.5, gris, como la maqueta) y como chip en `Perfil-vendedor`.
3. **R3 · "Vendedor confiable":** `TrustedBadge` (escudo y verde de "Precio justo"): compacta en `Producto` y chip en `Perfil-vendedor`.
4. **R4 · No se inventa:** sin datos no aparece ninguna.

## Diseño
- `lib/features/profile/`: `domain/profile_models.dart` (`responseMinutes`, `trusted`, `responseLabel`, `approxDuration`), `data/http_profile_repository.dart` y `presentation/trusted_badge.dart`.
- Cambios: `seller_profile_screen.dart` (fila de chips) y `product_screen.dart` (`_SellerCard`).

## Contratos
Fila `GET /api/v1/profiles/{id}` de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) (`stats.responseMinutes`, `stats.trusted`).

## Tests
- `test/features/profile/http_profile_repository_test.dart`: mapea las dos insignias y su ausencia.
- `test/features/profile/seller_profile_screen_test.dart`: los chips, sin datos y el redondeo.
- `test/features/marketplace/product_screen_test.dart`: la tarjeta con y sin insignias.
- `tool/screenshots_test.dart`: `perfil-vendedor` con "Responde en ~1 h" (como la maqueta) y "Vendedor confiable".

## Criterios
- [x] "Responde en ~N" con la mediana de 30 días → `"Responde en ~1 h" y "Vendedor confiable" junto a "desde"`, `"Responde en" redondea como la maqueta`, `quien vende: "Responde en ~1 h" y "Vendedor confiable"`.
- [x] "Vendedor confiable" con 4.5 ★ y 5 ventas → las mismas pruebas (la regla está en `musubi-api:HU-64`).
- [x] "Estudiante UTTT verificado" → la insignia de verificación de siempre (sin cambios).
- [x] Se calculan en la API, nunca en el teléfono → la app solo lee `stats`.
- [x] Sin datos no se muestran → `sin datos no se inventan las insignias`.
- [x] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` 791 · critic PASS · capturas lado a lado con la maqueta.

## Límites
- En pantallas angostas "Vendedor confiable" baja a una segunda línea de chips en `Perfil-vendedor`.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 16-Nov-2026 (detallada e implementada, con las decisiones de la usuaria; API `0.5.0-alpha.38`)
