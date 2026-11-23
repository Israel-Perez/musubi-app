# HU-58 — Ver un precio sugerido y saber si un precio es bueno (ML) (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-58 / SCRUM-98 / Sprint 5 (14 nov – 1 dic 2026) / M-11 / [musubi-api:HU-58](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m11-recommendations/HU-58-precio-sugerido)

## Contexto
Jira (SCRUM-98):
- Como **vendedor**, quiero **ver un precio sugerido al publicar**, para **poner un precio justo y vender más rápido**.
- Como **comprador**, quiero **saber si un precio es bueno comparado con productos parecidos**, para **decidir con confianza**.

- Pantallas:
  - `Vender-3` (y editar): la tarjeta de la maqueta "Productos parecidos se venden entre $X y $Y" con su barra.
  - `Producto` → "Compara antes de comprar": el veredicto de la maqueta (HU-51).
- El modelo de ML vive en la API (regresión de ML.NET por campus). La app lo muestra **sin quitar nada** de la maqueta (lineamiento 4):
  - con sugerencia, la misma tarjeta dice "Precio sugerido: $X – $Y";
  - en "Compara antes de comprar" se suma una fila con la estimación.

**Depende de:** `HU-06`/`HU-07` (publicar y editar), `HU-51` ("Compara antes de comprar"), `02-04` (piezas de la maqueta).

## Requisitos
1. **R1 · `Vender-3`:**
   - Con nombre (3 o más letras) y categoría, pide `POST /products/price-suggestion` con el nombre, la categoría y el estado del borrador.
   - Con rango, la tarjeta dice "Precio sugerido: $400 – $520" y "Estimado con 31 precios de tu campus. Tú decides el precio.", con la misma barra, la marca del precio y el mensaje de la maqueta.
   - Sin rango (pocos datos o si falla), queda el rango de la categoría de la maqueta.
2. **R2 · Solo una sugerencia:** el precio es siempre el que escribe la persona (RN-38). La app nunca lo cambia.
3. **R3 · `Producto`:**
   - "Compara antes de comprar" pide `GET /products/{id}/price-estimate`.
   - Con rango, debajo de "Esta publicación: $450 · promedio $443" dice "Musubi estima $400 – $520 para algo así · precio justo".
   - Sin rango no muestra nada nuevo.

## Diseño
- `PriceQuery` (record) y `PriceSuggestion` en `listing_models.dart`; `ListingsRepository.suggestPrice` y `priceSuggestionProvider`.
- `PriceEstimate` en `comparison.dart`; `ComparisonRepository.estimate` y `priceEstimateProvider`.
- `_PriceRangeCard` de `sell_price_screen.dart` (parámetro `suggestion`) y `_PriceCard` de `compare_section.dart` (parámetro `estimate`).

## Contratos
Filas `POST /api/v1/products/price-suggestion` y `GET /api/v1/products/{id}/price-estimate` de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md); error `recommendations.invalid_price_request`.

## Tests
- `test/features/listings/sell_flow_test.dart`:
  - con el modelo: "Precio sugerido", los precios, la barra, lo que se manda y que el precio no cambia;
  - sin el modelo: el rango de la categoría.
- `test/features/marketplace/product_screen_test.dart`: la fila de la estimación, y que sin ella no sale.
- `test/features/listings/http_listings_repository_test.dart` y `test/features/marketplace/comparison_test.dart`: el cuerpo, la lectura y `null` sin datos.
- `test/integration/sell_flow_test.dart`: contra la API real, las dos llamadas y el 400.

## Criterios
- [x] Al publicar o editar se muestra "Precio sugerido: $X – $Y"; es solo una sugerencia → `con el modelo de ML dice Precio sugerido…`.
- [x] En `Producto`, el veredicto (regla de la maqueta) y la estimación del modelo → `con la estimacion del modelo, la fila de Musubi`.
- [x] Con pocos datos no se muestra nada nuevo → `sin datos del modelo queda el rango de la categoria`, `precio sugerido sin datos`.
- [ ] Prueba en el celular (T4).

## Límites
- En `Vender-3` el estado se elige después (`Vender-4`): mientras tanto se usa el del borrador ("Como nuevo"). En editar ya es el real.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 23-Nov-2026 (detallada e implementada)
