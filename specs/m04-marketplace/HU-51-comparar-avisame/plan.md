# plan.md — HU-51 Comparar opciones y pedir aviso de disponibilidad (app)

## 1. Componentes
- Nuevos en `lib/features/marketplace/`: `domain/comparison.dart`, `data/http_comparison_repository.dart`, `presentation/comparison_providers.dart` y `presentation/compare_section.dart`.
- Cambios:
  - `product_screen.dart` (el comparador, "Avísame" ↔ "Te avisaremos", "Ver parecidos" y "Ver todas");
  - `search_screen.dart` y `router.dart` (`SearchScreen.initialFilter` por `extra`);
  - `product_detail.dart` y los repositorios del catálogo (`categorySlug`);
  - `account_gate.dart` y `account_gate_art.dart` (`AccountGateMotive.alert`, `AlertArt`);
  - `notifications_screen.dart` (`back_in_stock`);
  - `api_paths.dart`, `musubi_tokens.dart` (`brandWash`, `infoSoft`, `infoText`) y `musubi_icons.dart` (`trendingUp`, `starOutline`).

## 2. Decisiones (con su porqué)
- **La API elige y la app ordena:** las pestañas cambian sin otra llamada; el puntaje copia `compareVals` de la maqueta y se prueba con los valores que da esa función.
- **Orden estable:** en un empate se queda el orden de la API, como el `sort` estable del navegador.
- **El promedio va en pesos cerrados ("$443")**, como la maqueta, y el veredicto se calcula con ese promedio.
- **Sin sesión no se pide el comparador ni el estado del aviso** (RNF-05); "Avísame" abre su hoja de la maqueta.
- **El toque de "Avísame" cambia al instante** y regresa si la API falla; el estado se vuelve a leer después.
- **El aviso breve sube 97 (la barra de abajo)** para no tapar el botón, como en `Vender`.

## 3. Excepciones al stack
Ninguna.

## 4. Guardarraíles
- El aviso es de quien lo pide: la ruta no lleva su id.
- Las pruebas corren con Ahem: las tarjetas de opción usan `Wrap` y textos de una línea con elipsis.

## 5. Validación
Pruebas de dominio, repositorio y widget; capturas lado a lado con la maqueta (Edge sin ventana); prueba en el celular con la API `0.5.0-alpha.37` (T5).

## 6. Secuencia
Dominio y repositorio → providers → `CompareSection` → `Producto` → la hoja sin cuenta → avisos → pruebas → capturas → documentación.
