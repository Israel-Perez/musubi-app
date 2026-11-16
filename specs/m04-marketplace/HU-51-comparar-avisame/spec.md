# HU-51 — Comparar opciones y pedir aviso de disponibilidad (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-51 / SCRUM-70 / Sprint 5 (14 nov – 1 dic 2026) / M-04 / [musubi-api:HU-51](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m04-marketplace/HU-51-comparar-avisame)

## Contexto
Jira (SCRUM-70): Como **comprador**, quiero **comparar un producto con publicaciones similares y pedir un aviso cuando vuelva a estar disponible**, para **elegir la mejor opción y no perder un producto agotado**.

- Maqueta: `Producto` ("Compara antes de comprar", "Avísame" / "Te avisaremos", "Ver parecidos") y `Producto-visitante` (la hoja "Te avisamos si vuelve").
- Origen: maqueta (sección 3, G-04). Trazabilidad: RNF-03, RNF-05.
- **Decisiones de la usuaria (16-Nov-2026):**
  - **"Similar" es la regla de la maqueta** (misma categoría, el mismo modelo primero y luego el precio más cercano), sin el ML de HU-35.
  - **Las dos secciones conviven en `Producto`:** el comparador después de quien vende y "Productos parecidos" (HU-35) al final.
  - **El aviso se usa una vez:** al avisar se borra.

**Depende de:** `02-04` (piezas de la maqueta), `HU-11` (`Producto`), `HU-35` ("Productos parecidos"), `HU-31` (avisos), `HU-10` (búsqueda con filtros).

## Requisitos
1. **R1 · Comparar:** con sesión, `Producto` muestra "Compara antes de comprar": "5 opciones en UTTT · 2 del mismo modelo", la barra "Este modelo en UTTT" (o la categoría) con su veredicto ("Buen precio", "Precio justo" o "Arriba del promedio"), el más bajo, el más alto y el promedio.
2. **R2 · Ordenar:** "Para ti" (45 % reputación ponderada, 25 % ventas, 30 % precio y un extra por el mismo modelo), "Reputación", "Ventas" y "Precio". Cada opción trae su lugar, "Mejor opción" (solo en "Para ti"), las insignias "Mejor reputación", "Más ventas" y "Precio más bajo", "Mismo modelo", la diferencia de precio y quien vende con su calificación y ventas.
3. **R3 · Ir:** tocar una opción abre su detalle; "Ver todas las calculadoras" abre la búsqueda con esa categoría.
4. **R4 · Avísame:** en una agotada ajena, "Avísame" pasa a "Te avisaremos" (verde) con "Te avisaremos cuando vuelva «…»"; tocarlo otra vez lo quita ("Quitaste el aviso"). Sin cuenta abre "Te avisamos si vuelve".
5. **R5 · Ver parecidos:** en una agotada baja al comparador (o a "Productos parecidos" si no hay opciones).
6. **R6 · El aviso:** `back_in_stock` ("¡Volvió lo que esperabas!") aparece en "Coincidencias" y abre la publicación (destino `product`, HU-31).

## Diseño
- `lib/features/marketplace/`:
  - `domain/comparison.dart`: `ComparisonOption`, `Comparison` (`ranked`, `priceBand`), `CompareOrder`, `CompareBadge`, `PriceVerdict` y `ComparisonRepository`.
  - `data/http_comparison_repository.dart`.
  - `presentation/comparison_providers.dart` (`comparisonProvider`, `stockAlertProvider`) y `compare_section.dart` (`CompareSection`, `OptionCard`).
- Cambios: `product_screen.dart`, `search_screen.dart` (`initialFilter`), `router.dart`, `account_gate.dart` (`AccountGateMotive.alert` y `AlertArt`), `notifications_screen.dart`, `ProductDetail.categorySlug`, tokens `brandWash`, `infoSoft` e `infoText`, y el ícono `trendingUp`/`starOutline`.

## Contratos
Filas "M-03" de HU-51 en [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md) (`GET /products/{id}/compare` y `GET`/`PUT`/`DELETE /products/{id}/stock-alert`), enlazadas desde `lib/core/network/api_paths.dart`; errores `listings.product_available`, `listings.own_product` y `listings.too_many_stock_alerts` (la app muestra el mensaje).

## Tests
- `test/features/marketplace/comparison_test.dart`: los cuatro órdenes, las insignias y la barra contra los valores de la maqueta (`compareVals` corrido con la Casio de Valeria), y el repositorio HTTP (rutas, forma y un 409).
- `test/features/marketplace/product_screen_test.dart` (grupo HU-51): el comparador con sesión, "Precio", tocar una opción, "Ver todas", sin opciones, visitante, "Avísame" ↔ "Te avisaremos", ya pedido, error de la API, "Ver parecidos" y lo propio.
- `tool/screenshots_test.dart`: `producto-compara`, `producto-compara-opciones`, `producto-compara-precio`, `producto-te-avisaremos` y `producto-avisame-visitante`.

## Criterios
- [x] El detalle muestra publicaciones similares comparadas por reputación del vendedor, ventas y precio → `"Para ti" combina reputación, ventas y precio, como la maqueta`, `con sesion: la barra de precios, la mejor opción y el orden`.
- [x] En un producto agotado, "Avísame" registra el interés → `agotado: "Avísame" pasa a "Te avisaremos" y se puede quitar`.
- [x] Cuando el producto vuelve a tener existencias llega una notificación push → `musubi-api:HU-51` (`back_in_stock`) y el destino `product` de HU-31.
- [x] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` 787 · critic PASS.

## Límites
- Sin sesión no hay comparador: compara a quienes venden y un visitante no los ve (RNF-05). La maqueta sí lo muestra en `Producto-visitante`.
- Las iniciales de quien vende usan la paleta de la app (por su id), no el color de cada persona de la maqueta.
- La maqueta compara con la "HP 10bII+" en el quinto lugar; las capturas usan la "fx-991LA CW" porque la app no trae la foto de la HP.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026 (borrador ligero) · 16-Nov-2026 (detallado e implementado, con las decisiones de la usuaria)
