# plan.md — HU-64 Ver insignias de confianza de quien vende (app)

## 1. Componentes
- `lib/features/profile/domain/profile_models.dart`, `data/http_profile_repository.dart`, `presentation/trusted_badge.dart` (nuevo) y `presentation/seller_profile_screen.dart`.
- `lib/features/marketplace/presentation/product_screen.dart` (`_SellerCard`).

## 2. Decisiones (con su porqué)
- **Las reglas viven en la API:** la app solo lee `stats` (criterio de Jira).
- **El redondeo copia la maqueta** ("~1 h"): cuartos de hora hasta 45 min, luego horas y días.
- **"Vendedor confiable" con las piezas de la maqueta:** el verde de "Precio justo" y el escudo de "Verificada"; compacta en la tarjeta y del tamaño de los chips en el perfil.

## 3. Excepciones al stack
Ninguna.

## 4. Guardarraíles
Sin datos no se muestra nada; en Ahem la pastilla es `Flexible` dentro de la fila.

## 5. Validación
Pruebas de repositorio y de widget, capturas lado a lado y prueba en el celular con la API `0.5.0-alpha.38` (T5).

## 6. Secuencia
Modelo y repositorio → `TrustedBadge` → `Perfil-vendedor` → `Producto` → pruebas → capturas → documentación.
