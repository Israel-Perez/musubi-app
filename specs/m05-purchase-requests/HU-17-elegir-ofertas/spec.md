# HU-17 — Ver y elegir ofertas recibidas (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-17 / SCRUM-39 / Sprint 4 (9 – 20 nov 2026) / M-05 / [musubi-api:HU-17](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m05-purchase-requests/HU-17-elegir-ofertas)

## Contexto
Jira (SCRUM-39): Como **comprador**, quiero **ver las ofertas que recibí en mi solicitud**, para **comparar opciones y elegir la que más me convenga**.

- Maqueta: `Mis-solicitudes` ("Compara las ofertas" y "Ordenar ofertas") y `Chat-Valeria` (la conversación que abre una oferta).
- Trazabilidad: RF-21 · CU-12.

**Depende de:** `HU-13` (Mis solicitudes), `HU-16` (ofertas) y `HU-20` (chat).

## Requisitos
1. **R1 · Compara las ofertas:** cada oferta con quien ofrece (nombre, insignia, ★ promedio, número de calificaciones o "Sin calificaciones" y carrera), la etiqueta "Mejor reputación" o "Menor precio", la foto, el precio con "$100 bajo tu presupuesto" o "arriba de tu presupuesto", su mensaje y "Usado · con detalles · Su publicación" u "Oferta directa".
2. **R2 · Ordenar ofertas:** Recomendadas (las aceptadas primero, luego las que caben en el presupuesto, mejor reputación y menor precio), Menor precio y Mejor reputación.
3. **R3 · Rechazar:** diálogo "¿Rechazar la oferta de Diego?", la oferta desaparece y el aviso trae "Deshacer". La API se llama al terminar el aviso (o al salir de la pantalla). Si se rechazan todas: "Rechazaste todas las ofertas…".
4. **R4 · Aceptar:** diálogo "¿Aceptar la oferta de Valeria?"; abre el chat con "¡Hola, Valeria! Acepto tu oferta de $450. ¿Cuándo nos vemos?" escrito en la caja. Una oferta aceptada muestra "Aceptada" y solo "Abrir chat".
5. **R5 · Abrir chat:** abre la conversación de la oferta sin decidir.
6. **R6 · El chat de una oferta:** la tarjeta dice "OFERTA DE VALERIA · SE BUSCA" (o "TU OFERTA · SE BUSCA" para quien ofreció) y no tiene "Ver".
7. **R7 · Quien ofrece:** si su oferta ya fue elegida o rechazada, la hoja de HU-16 lo dice ("Fernanda rechazó tu oferta") y no deja enviarla.

## Diseño
- `lib/features/purchase_requests/`:
  - `domain/offer_models.dart` (`ReceivedOffer`, `Offerer`, `OfferStatus`);
  - `WantedRepository.receivedOffers`, `rejectOffer`, `acceptOffer` y `offerChat`;
  - `receivedOffersProvider`;
  - `presentation/received_offers.dart` (`ReceivedOffersSection`, `OfferCompareCard` y `sortOffers`).
- Chat: `ChatContext.type`/`isOffer`, `ChatScreen.draft` (la ruta `/chat/:id` lo recibe como `extra`) y la tarjeta del contexto para ofertas.

## Contratos
Filas `GET /api/v1/wanted/{requestId}/offers` y `POST .../offers/{offerId}/reject`, `accept` y `chat` de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md), enlazadas desde `ApiPaths.receivedOffers` y `ApiPaths.offerAction`.

## Tests
- `test/features/purchase_requests/received_offers_test.dart`: R1–R6 y el orden (`sortOffers`).
- `test/features/purchase_requests/wanted_data_test.dart`: lista, acciones y el estado de mi oferta.
- `test/features/purchase_requests/offer_test.dart`: R7.
- `tool/screenshots_test.dart`: `mis-solicitudes-ofertas`.

## Criterios
- [x] El comprador ve las ofertas recibidas en cada solicitud (R1, R2).
- [x] Desde cada oferta puede abrir un chat con quien ofrece, rechazarla o aceptarla (R3–R5).
- [ ] Aceptar una oferta inicia un pedido: `NOTE (HU-23)`. Aceptar abre el chat; el pedido sale de la oferta aceptada.
- [x] Capturas iguales a la maqueta (tarjeta de 217 pt en las dos).
- [x] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` 418/418 · critic PASS.

## Límites
- `NOTE (HU-23)`: el pedido desde la oferta aceptada.
- `NOTE (HU-30)`: "Le avisaremos con un mensaje amable" al rechazar.
- `NOTE (HU-32)`: "Después resumimos el acuerdo con IA".
- La maqueta dice "Usada · como nueva" (calculadora); la app usa el masculino ("Usado · como nuevo") para cualquier producto.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026 (borrador) · 09-Nov-2026 (implementación)
- **Detalle:** "Deshacer" espera al final del aviso antes de rechazar; el orden lo hace la app.
