# plan.md — HU-07 Editar o eliminar mis publicaciones (app)

1. **Componentes:**
   - `domain/listing_models.dart` (`ListingUpdate`; `OwnListing` con `description`, `condition`, `usedDetail` y `paused`) y `domain/listings_repository.dart` (`update`, `pause`, `resume` y `delete`);
   - `data/http_listings_repository.dart` y `core/network/api_paths.dart` (`productPause` y `productResume`);
   - `presentation/sell_draft.dart` (`SellDraft.editing`, `editingId`, `coverUrl`, `sellEditDraftProvider`, `sellDraftFor`, `load` y `saveEdit`) y `presentation/sell_edit.dart` (nuevo);
   - `presentation/sell_details_screen.dart`, `sell_price_screen.dart` y `sell_condition_screen.dart` con `editing`;
   - `presentation/my_products_screen.dart` (menú, diálogo y "Pausada");
   - `app/router.dart` (3 rutas `/editar-publicacion…`);
   - pruebas y `tool/screenshots_test.dart` (3 escenas).
2. **Decisiones:**
   - **Borrador aparte para editar** (`sellEditDraftProvider`, como `needEditDraftProvider` de HU-14): editar no pisa un borrador de venta guardado con "Guardar".
   - **Mismas pantallas con `editing`**, sin copias: la maqueta reutiliza `Vender-2…4`.
   - **"Guardar" de arriba y "Guardar cambios" mandan lo mismo**, como en "Editar solicitud".
   - **Volver con `popUntil` hasta `/mis-productos`:** go_router 18.1 nombra cada página con su ruta (`state.path`), así se sale desde cualquier paso sin rehacer la pila.
   - **Pausar en el menú** (decisión de la usuaria): `eyeOff`/`eye` y una línea que explica qué pasa. La pausada sigue en "Activos" con "Pausada" y la foto en gris.
   - **Piezas visibles sin editar** (decisión de la usuaria): el contador queda deshabilitado con "Cámbialas desde Mis productos" (HU-50).
   - **El `409 listings.product_has_orders` se muestra con el mensaje de la API** (ya dice qué hacer); un `404` refresca la lista.
   - **La vitrina se refresca** (`homeFeedProvider`) después de editar, pausar o eliminar.
3. **Excepciones al stack (00-01):** ninguna.
4. **Guardarraíles:** sin Dio en la UI (pantalla → borrador o repositorio → `ApiFailure`); mensajes de la API por `code`; sin `print` ni `TODO`.
5. **Validación:** las pruebas de la `spec.md`, capturas en claro, `dart format`, `flutter analyze`, `flutter test` y critic.
6. **Secuencia:** dominio y datos → borrador de editar → pasos con `editing` y rutas → menú de `Mis-productos` → pruebas → capturas → documentación.
