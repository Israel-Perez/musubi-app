# plan.md — HU-50 Manejar la cantidad disponible de un producto (app)

1. **Componentes:**
   - `domain/listings_repository.dart`, `data/http_listings_repository.dart` y `core/network/api_paths.dart` (`setStock` y `productStock`);
   - `presentation/quantity_row.dart` (nuevo; sale de `sell_condition_screen.dart`) y `presentation/my_products_screen.dart`;
   - pruebas y 2 escenas de captura.
2. **Decisiones:**
   - **Menú y "Reponer"** (decisión de la usuaria): la hoja con el selector cubre cualquier número, y "Reponer" es el atajo de la maqueta para una agotada.
   - **Una petición por cambio:** la hoja manda el número final al tocar "Guardar", no un `+1/−1` por toque.
   - **El mismo selector que `Vender-4`** (`QuantityRow`), con un mínimo de 0 al cambiar.
   - **El aviso dice qué pasó:** "Ya aparece como agotado" con 0.
3. **Excepciones al stack (00-01):** ninguna.
4. **Guardarraíles:** sin Dio en la UI; el error de la API se muestra por `code`.
5. **Validación:** pruebas, capturas, formato, análisis, pruebas completas y critic.
6. **Secuencia:** datos → `QuantityRow` compartido → menú y "Reponer" → pruebas → capturas → documentación.
