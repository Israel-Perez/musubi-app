# HU-52 — Apartar un producto y verificar la entrega con QR o código (app)

**HU / Jira / Sprint / Módulo / Contraparte:** HU-52 / SCRUM-74 / Sprint 5 (14 nov – 1 dic 2026) / M-08 / [musubi-api:HU-52](https://github.com/Israel-Perez/musubi-api/tree/main/specs/m08-orders/HU-52-apartar-producto)

## Contexto
Jira (SCRUM-74): Como **comprador**, quiero **apartar un producto por 24 horas y recibir un QR o un código**, para **que el vendedor me lo guarde y verifique que soy yo al entregarlo**.

- Maqueta: `Producto` ("Apártalo 24 h sin pagar" y "Apartar"), `Apartar`, `Apartado-listo`, `Mis-apartados`, `Verificar-comprador`, `Apartado-verificado` y la tarjeta "Mis apartados" de `Perfil`.
- Origen: maqueta (sección 4, G-05). Trazabilidad: RNF-03.
- **Decisiones de la usuaria (15-Nov-2026):**
  - **Un apartado activo** por comprador a la vez.
  - **QR y cámara completos:** `qr_flutter` y `mobile_scanner`, con su excepción de 00-01 (ver `plan.md`) y el permiso de cámara.
  - **Al confirmar la entrega nace un pedido completado** (ventas, "Mis pedidos" y calificaciones).

**Depende de:** `02-04` (piezas de la maqueta), `HU-11` (`Producto`), `HU-23`/`HU-44` (puntos de entrega), `HU-31` (avisos), `HU-27` (calificar).

## Requisitos
1. **R1 · Apartar (`Apartar`):** "Apartar" y "Apártalo 24 h sin pagar" de `Producto` abren la hoja con el producto, "Te lo guarda 24 h · Pagas al recoger", tres horas ("¿Cuándo pasas?") y los puntos del campus ("¿Dónde?"). Al apartar abre `Apartado-listo`.
2. **R2 · QR y código (`Apartado-listo`):** el boleto rojo con el QR (`musubi:apartado:{id}:{code}`) y "O DICTA TU CÓDIGO 482 173", el punto, la hora y "Vence en 24 h"; "Mensaje", "Mis apartados" y "Cancelar apartado" (con confirmación).
3. **R3 · Mis apartados (`Mis-apartados`):** "Yo aparté (n)" con "Mostrar mi QR" y "Me apartaron (n)" con "Verificar comprador"; la tarjeta de `Perfil` dice cuántos faltan ("1 por recoger hoy · 1 te apartaron").
4. **R4 · Verificar (`Verificar-comprador`):** quien vende escanea el QR con la cámara (solo el de ese apartado) o escribe el código; la API cuenta los intentos (5) y la app dice cuántos quedan.
5. **R5 · Entregar (`Apartado-verificado`):** "Comprador verificado" con su carrera y calificación, el producto y "Cobra en efectivo"; "Confirmar entrega" crea el pedido completado ("¡Entregado!") y "No es esta persona" regresa a verificar.
6. **R6 · Avisos:** el destino `reservation` (HU-31) abre el apartado.

## Diseño
- `lib/features/orders/`:
  - `domain/reservation_models.dart`: `Reservation`, `ReservationPage`, `ReservationRepository`, `PickupSlots` (las horas) y `codeFromQr`.
  - `data/http_reservation_repository.dart`.
  - `presentation/`: `reserve_sheet.dart` (`showReserveSheet`), `reservation_screen.dart`, `my_reservations_screen.dart` (con `MyReservationsTile`) y `verify_buyer_screen.dart` (`VerifyBuyerScreen`, `BuyerVerifiedScreen` y `qrCameraProvider`).
- Rutas: `AppRoutes.reservation`, `verifyBuyer`, `buyerVerified` y `myReservations` (con sesión).
- Android: permiso `CAMERA`, la cámara no es requisito (`uses-feature required=false`) y ML Kit sin empaquetar (`gradle.properties` y `com.google.mlkit.vision.DEPENDENCIES`).

## Contratos
Sección "Apartados (HU-52)" de [`musubi-api/docs/endpoints.md`](https://github.com/Israel-Perez/musubi-api/blob/main/docs/endpoints.md), enlazada desde `lib/core/network/api_paths.dart`; errores `reservations.*` de `docs/errores.md` (la app decide por `code`).

## Tests
- `test/features/orders/reservations_test.dart`: las horas (siempre dentro de las 24 h y de 7:00 a 21:00), el QR de otro apartado, el repositorio HTTP (rutas, cuerpo y `?tab=`), apartar desde `Producto`, el límite de uno, cancelar, las dos pestañas, la tarjeta de `Perfil`, verificar con la cámara y con el código (intentos), entregar, el aviso y la sesión.
- `test/security/android_config_test.dart`: `CAMERA` aprobado y la cámara no requerida.
- `tool/screenshots_test.dart`: `apartar`, `apartado-listo`, `apartado-cancelar`, `mis-apartados`, `mis-apartados-vendedor`, `verificar-comprador`, `verificar-codigo`, `apartado-verificado` y `perfil`.

## Criterios
- [x] Al apartar se eligen la hora y el punto de entrega; vence a las 24 horas → `"Apartar" del producto elige hora y punto y abre el QR`, `siempre dentro de las 24 h y de 7:00 a 21:00`.
- [x] El comprador recibe un QR y un código de 6 dígitos → mismo test (`reservation-qr` y "482 173").
- [x] El vendedor escanea el QR o escribe el código; solo el de ese apartado → `el QR de otro apartado no se acepta y el correcto verifica`, `"Escribir código": uno equivocado gasta un intento`.
- [x] "Mis apartados" muestra lo que aparté y lo que me apartaron → `"Yo aparté" muestra mi QR y "Me apartaron" verifica`.
- [x] El código no se adivina por fuerza bruta → 5 intentos en la API (`musubi-api:HU-52`) y "te quedan 4 intentos" en la app.
- [x] `dart format` sin cambios · `flutter analyze` 0 · `flutter test` 749 al 100 % · critic PASS.

## Límites
- Las tres horas salen de la hora actual (10:00, 13:00 y 17:00 de hoy y mañana dentro de la ventana); la maqueta muestra "Mañana 10:00 a. m." a las 9:41, que ya pasa de las 24 h: la app da "Mañana 9:00 a. m.".
- El QR de la API tiene 47 caracteres (versión 3, 29 módulos); el de la maqueta es ilustrativo (21).
- Sin la cámara (permiso negado o sin el lector de ML Kit) se escribe el código.

## Aprobación y Control de Cambios
- **Estado:** 🚧 Borrador con evidencia
- **Revisores:** Pendiente de designar (1 integrante distinto del autor)
- **Fecha:** 29-Oct-2026 (borrador ligero) · 15-Nov-2026 (detallado e implementado, con las decisiones de la usuaria)
