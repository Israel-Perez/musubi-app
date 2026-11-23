# plan.md — HU-58 Ver un precio sugerido y saber si un precio es bueno (app)

## 1. Componentes
- `listing_models.dart` (`PriceQuery`, `PriceSuggestion`), `listings_repository.dart`, `http_listings_repository.dart` y `priceSuggestionProvider`.
- `comparison.dart` (`PriceEstimate`), `http_comparison_repository.dart` y `priceEstimateProvider`.
- `sell_price_screen.dart` y `compare_section.dart`.
- `ApiPaths.priceSuggestion` y `ApiPaths.productPriceEstimate`.

## 2. Decisiones (con su porqué)
- **La misma tarjeta de la maqueta:** solo cambia la frase de arriba ("Precio sugerido") y se agrega de dónde sale. La barra, la marca y el mensaje no cambian (lineamiento 4).
- **`PriceQuery` es un record:** dos consultas iguales comparten el provider. Escribir el precio no vuelve a pedir la sugerencia, porque el precio no va en la consulta.
- **Si la sugerencia falla, se queda la de la categoría:** el provider no reintenta y la pantalla no muestra errores de la sugerencia.

## 3. Excepciones al stack
Ninguna.

## 4. Guardarraíles
- Sin datos nuevos en el teléfono. Las dos llamadas van con sesión al host de la API (`AuthInterceptor`).

## 5. Validación
`flutter analyze`, `flutter test`, `scripts/run_integration_tests.ps1` y prueba en el celular (T4).

## 6. Secuencia
T1 → T2 → T3 → T4.
