# HU-45 — Calificar al comprador al terminar un pedido (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-45 / SCRUM-50 / Sprint 4 (9 – 20 nov 2026) / M-13 / [musubi-api:HU-45](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m13-reputation/HU-45-calificar-comprador)

## Contexto
Jira (SCRUM-50): Como **vendedor**, quiero **calificar al comprador al terminar un pedido**, para **que la reputación refleje el comportamiento de ambas partes**.

- Maqueta:
  - `Calificar`: "Pedido completado", "¿Cómo te fue con Diego?", estrellas, "¿Qué destacas?", "Cuéntale a la comunidad", "Enviar calificación" y "Ahora no";
  - `Pedido-entrega`: al confirmar la entrega se pasa a `Calificar`;
  - `Perfil-vendedor`: "Opiniones" ("Lo que dicen de Valeria") y "A tiempo".
- Trazabilidad: RF-35, RF-36 · CU-19 · RN-24, RN-25, RN-26.
- HU-27 y HU-45 son la misma pantalla para las dos partes; se implementaron juntas (HU-27 es la otra mitad).
- **Decisiones de la usuaria (12-Nov-2026):** un solo promedio; 7 días para calificar; "A tiempo" es el porcentaje con "Puntual"; quien compra recibe sus chips (Puntual, Buena comunicación, Amable y Pagó lo acordado).

**Depende de:** `02-04` (piezas de la maqueta), `HU-24` ("Tu pedido"), `HU-05` (`Perfil-vendedor`) y la API de HU-27/HU-45.

## Requisitos
1. **R1 · Entrar a `Calificar`:** al confirmar la entrega que completa el pedido se abre `Calificar` (como la maqueta). Un pedido completado, sin calificar y dentro del plazo muestra "Calificar a Diego" en "Tu pedido".
2. **R2 · `Calificar`:**
   - Estrellas de 1 a 5, empieza en 5, con las palabras de la maqueta ("Muy mala" a "¡Excelente!").
   - "¿Qué destacas?": quien compra ve los cinco chips de la maqueta; quien vende, los de quien compra. Se mandan en el orden de la lista.
   - Comentario opcional de hasta 280 caracteres.
   - "Enviar calificación" lleva a Inicio con "¡Gracias! Tu calificación ya está en el perfil de Diego."; "Ahora no" y la X regresan sin calificar.
3. **R3 · Después de calificar:** "Tu pedido" dice "Pedido completado. Ya calificaste a Diego." y ya no ofrece calificar. Fuera de plazo tampoco.
4. **R4 · Errores:** un error de la API se explica y la pantalla se queda; "ya calificado" o "fuera de plazo" regresan a "Tu pedido" actualizado.
5. **R5 · Chat:** bajo el nombre de la otra persona va "★ 4.6" cuando tiene calificaciones (maqueta "★ 4.6 · Activa hace 5 min"; la API no expone la presencia).
6. **R6 · `Perfil-vendedor`:** "Opiniones" muestra "Lo que dicen de Valeria" con estrellas, fecha, comentario y "Luis M. · Puntual", y "Ver más". "A tiempo" muestra el porcentaje, o "—" sin calificaciones.

RNF que aplican: RNF-18 (mensajes en español), RNF-20 (contraste) y RNF-27 (toques de 44: estrellas de 50 y chips de 44 de alto).

## Diseño
- **Dominio:** `RatingTag` (código, texto y listas por rol), `ratingWords`, `NewRating`, `Opinion` y `OpinionPage`; `Order.ratedByMe`, `rateUntil` y `canRate(now)`; `PublicProfile.onTime`.
- **Datos:** `ReputationRepository.rate` y `opinions` (`ApiPaths.orderRating`, `ApiPaths.profileRatings`).
- **Pantallas:** `RateScreen` (`AppRoutes.rate`, `/pedido/:id/calificar`); `OrderPaymentScreen` (botón "Calificar a …" y paso a `Calificar` al completar); `SellerProfileScreen` (opiniones con `opinionsProvider` y "A tiempo").

## Contratos
Filas "M-13" de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md): `POST /api/v1/orders/{id}/rating` y `GET /api/v1/profiles/{id}/ratings`; `OrderResponse.ratedByMe`/`rateUntil` y `stats.onTime` del perfil público.

## Tests
- `test/features/reputation/http_reputation_repository_test.dart` (+5): calificar, sin comentario, opiniones con cursor y chips desconocidos, `ratings.already_rated` y las listas.
- `test/features/orders/order_data_test.dart` (+1): `ratedByMe`, `rateUntil` y `canRate`.
- `test/features/reputation/rate_flow_test.dart` (9): ofrecer "Calificar", enviar, chips de quien vende, "Ahora no", ya calificado, fuera de plazo, completar abre `Calificar`, error y accesibilidad a 360×640.
- `test/features/profile/seller_profile_screen_test.dart` (+3): opiniones con "Ver más", "A tiempo" y error.
- `test/features/orders/order_flow_test.dart`: completar ahora pasa por `Calificar` y "Ahora no" regresa.
- `test/features/chat/chat_flow_test.dart` (+1): la calificación en el encabezado.
- `tool/screenshots_test.dart`: `calificar` y `perfil-vendedor-opiniones`, comparadas con la maqueta.

## Criterios
- [x] Solo se califica un pedido completado, una vez por parte → `rate_flow_test` (ya calificado, fuera de plazo).
- [x] Escala de 1 a 5 y comentario opcional → `elegir estrellas, chips y comentario y enviar`.
- [x] La reputación (promedio y número) se ve en el perfil y en las publicaciones; "A tiempo" y "Opiniones" en `Perfil-vendedor` → `seller_profile_screen_test`.
- [x] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` 643 al 100 % · critic PASS.
- [ ] Prueba en el celular con la API desplegada (`alpha.25`, `db/020`).

## Límites
- Los chips de la maqueta no empiezan marcados: la persona elige los suyos.
- Sin aviso push de "Te calificaron" (la maqueta no lo tiene).

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026 (borrador ligero) · 12-Nov-2026 (detallado e implementado)
- **Detalle:** capturas comparadas con la maqueta (`Calificar` y `Perfil-vendedor`).
