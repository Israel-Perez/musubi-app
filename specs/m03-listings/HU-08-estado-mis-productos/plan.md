# plan.md — HU-08 Consultar el estado de mis productos (app)

1. **Componentes:**
   - `domain/listing_models.dart` (`sold`, `soldAt`, `MyProductsTab`, `MyListingsCounts` y `MyListingsPage`) y `domain/listings_repository.dart` (`minePage` y `markSold`);
   - `data/http_listings_repository.dart` y `core/network/api_paths.dart` (`productSold`);
   - `presentation/listings_providers.dart` (`myListingsTabProvider`) y `presentation/my_products_screen.dart`;
   - `marketplace/domain/home_feed.dart` (`dayMonth`);
   - pruebas y 2 escenas de captura.
2. **Decisiones:**
   - **Las pestañas y los conteos los da la API** (`?tab=` y `counts`): antes la app filtraba una sola lista, y "Vendidos" siempre decía 0.
   - **`mine()` se queda** para el Perfil y "Yo tengo este producto". Esos dos filtran por `active`, así que basta con leer `sold` como su propio estado.
   - **Diálogo de confirmación al vender:** el menú de `Mis-productos` de la maqueta vende sin preguntar, pero `Producto` sí pregunta con este texto. Como no se deshace, se usa el diálogo de la maqueta.
   - **Menú corto para una vendida:** solo "Ver publicación" y "Eliminar", para no ofrecer acciones que la API rechaza con 409.
   - **"Ver más" con el cursor de la API** en lugar de un scroll infinito: un estudiante tiene pocas publicaciones (50 por página).
   - **Total de "Vendidos" con el precio publicado** de las vendidas que se ven, hasta que los pedidos den el monto real (HU-25).
3. **Excepciones al stack (00-01):** ninguna.
4. **Guardarraíles:** sin Dio en la UI; mensajes de la API por `code` (`listings.product_sold` y `listings.product_not_found` refrescan la lista).
5. **Validación:** pruebas de la `spec.md`, capturas en claro, formato, análisis, pruebas y critic.
6. **Secuencia:** dominio y datos → proveedor por pestaña → pantalla → pruebas → capturas → documentación.
