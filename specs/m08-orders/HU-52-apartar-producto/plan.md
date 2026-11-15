# plan.md — HU-52 Apartar un producto y verificar la entrega con QR o código (app)

## 1. Componentes
- Nuevos en `lib/features/orders/`: `domain/reservation_models.dart`, `data/http_reservation_repository.dart`, `presentation/reserve_sheet.dart`, `reservation_screen.dart`, `my_reservations_screen.dart` y `verify_buyer_screen.dart`.
- Cambios:
  - `order_providers.dart` (`reservationRepositoryProvider`, `reservationProvider`, `myReservationsProvider`);
  - `api_paths.dart` y `router.dart` (rutas con sesión);
  - `product_screen.dart` ("Apartar"), `profile_screen.dart` (`MyReservationsTile`);
  - `notification_models.dart` y `notification_providers.dart` (destino `reservation`);
  - `musubi_icons.dart` (`mapPinRound`, `qrCodeLite`, `scan`, `scanLine`, `keyboard`, `flashlight`).
- Android: `AndroidManifest.xml` (`CAMERA`, `uses-feature` no requerido, `com.google.mlkit.vision.DEPENDENCIES`) y `gradle.properties` (ML Kit sin empaquetar).

## 2. Decisiones (con su porqué)
- **La cámara detrás de `qrCameraProvider`:** las pruebas y las capturas no tienen cámara; la vista fija de las capturas dibuja el QR girado de la maqueta.
- **El QR se valida en la app antes de llamar a la API** (`codeFromQr`): un QR de otro apartado no gasta un intento.
- **Las horas (`PickupSlots`):** botones como la maqueta; se completan desde el final de la ventana para no ofrecer una hora que la API rechace.
- **ML Kit sin empaquetar:** +600 KB en lugar de 3–10 MB; Play Services baja el lector al instalar (meta-data). Si no está, se escribe el código.
- **"Confirmar entrega" se queda en la pantalla** con "¡Entregado!" y "Listo" (como la maqueta) en lugar de abrir la calificación: quien compró recibe el aviso y califica desde su pedido.

## 3. Excepciones al stack (regla de 00-01)
Consultado en pub.dev el 15-Nov-2026 (licencias leídas del pub cache).

| Paquete | Versión | Licencia | Mantenimiento | Seguridad | Alternativa descartada | Plan de remoción |
|---|---|---|---|---|---|---|
| `mobile_scanner` | 7.5.0 (01-Nov-2026) | BSD-3 | Editor verificado `steenbakker.dev`; 160/160 puntos | Sin avisos; pide `CAMERA` (aprobado en `android_config_test`, cámara no requerida); ML Kit sin empaquetar | Canal propio a CameraX + ML Kit en Kotlin: más código nativo que mantener | Reemplazar `CameraQrView` (una clase detrás de `qrCameraProvider`) |
| `qr_flutter` | 4.1.0 | BSD-3 (su dependencia `qr` 3.0.3 también) | Editor verificado `theyakka.com`; 150/160 puntos (restricción de `qr`), estable desde hace 3 años | Sin avisos; solo dibuja (sin permisos ni red) | Dibujar el QR a mano con `qr`: el mismo paquete base y más código | Reemplazar `QrImageView` en `ReservationTicket` |

## 4. Guardarraíles
- El código y el QR solo llegan a quien apartó (la API los omite para los demás); la app no los guarda.
- El QR solo se acepta si es del apartado abierto; la API cuenta 5 intentos.
- Las pruebas corren con la fuente Ahem: los textos largos son `Flexible`.

## 5. Validación
Pruebas de modelo, repositorio y widget (`reservations_test.dart`), `android_config_test`, capturas lado a lado con la maqueta y prueba en el celular (T5).

## 6. Secuencia
Modelo y repositorio → rutas → `Apartar` → `Apartado-listo` → `Mis-apartados` y `Perfil` → `Verificar-comprador` y `Apartado-verificado` → Android → pruebas → capturas → documentación.
