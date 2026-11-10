# plan.md — HU-23 Confirmar la compra de un producto (app)

## 1. Componentes
- **Nuevo `lib/features/orders/`:**
  - `domain/order_models.dart` (`Order`, `OrderItem`, `OrderStatus`, `MeetingPoint` y `NewOrder`) y `domain/order_repository.dart`.
  - `data/http_order_repository.dart` (`orderFromJson`).
  - `presentation/order_providers.dart`, `order_summary_sheet.dart` ("Resumen del acuerdo" y sus paneles) y `order_payment_screen.dart` ("Tu pedido").
- **`lib/core/network/api_paths.dart`:** `orders`, `meetingPoints`, `order(id)` y `orderPayment(id)`, que citan las filas M-08.
- **Router:** `AppRoutes.orders` y `order(id)` (`/pedido/:id`), con sesión obligatoria.
- **Chat:** `_ContextCard` recibe el pedido abierto (`openOrderProvider`) y `ChatScreen._summarize` decide qué hace "Resumir acuerdo".
- **Piezas:** íconos `mapPin`, `arrowRightLeft`, `banknote`, `package` y `pencil` (Lucide de la maqueta); token `mutedChip`. `NeedChip` recorta los nombres largos.

## 2. Decisiones
- **Resumen sin IA (decisión de la usuaria, 10-Nov-2026):** es la hoja de `Acuerdo-esperando` (top 104, radio 28, filas editables y "No identificado" en ámbar con "Agregar"), sin el aviso de IA ni el estado "0 de 2". El encabezado usa el apretón de manos de `Acuerdo-confirmado` sobre rosa.
- **Producto y precio fijos (sin lápiz):** vienen de la publicación o de la oferta aceptada. La cantidad va hasta lo disponible del detalle (HU-11), con un máximo de 10; en una oferta, la API valida contra la solicitud.
- **Entrega:** chips con los puntos de la API, el edificio de la carrera primero (con birrete) y "Primero está el edificio de tu carrera."; detalle opcional de hasta 120 caracteres.
- **Fecha y hora:** hoy y los 13 días siguientes, de 7:00 a 21:00, cada hora, con al menos 30 minutos de anticipación (igual que la API).
- **`already_open`:** si otro toque o dispositivo ya creó el pedido, se abre ese.
- **`Pedido-pago`:**
  - el paso actual late 3 veces (`Pedido-pago__pulse`, 2 s);
  - la transferencia sale al 55 % con "… aún no registra su cuenta";
  - efectivo queda elegido y "Confirmar pago en efectivo" lo registra;
  - después, el botón es "Volver al chat";
  - el paso 3 de "Así funciona" no menciona el código de entrega, porque ese llega con HU-55.
- **Quien vende:** "Resumir acuerdo" le explica que el pedido lo crea quien compra; en "Tu venta" ve cómo le pagarán (aceptar es HU-24).

## 3. Excepciones al stack
Ninguna.

## 4. Guardarraíles
- Las fallas de la API se muestran con su mensaje en español y no se pierde lo capturado.
- `orderRepositoryProvider` usa el cliente con sesión, y la ruta `/pedido/` exige sesión.

## 5. Validación
- `test/features/orders/order_data_test.dart` (7) y `order_flow_test.dart` (15): resumen, paneles, crear, errores, `already_open`, el aviso del chat como comprador y como vendedor, "Tu pedido", pagar y "Tu venta".
- Capturas `resumen-acuerdo` y `pedido-pago`, en claro y oscuro, comparadas con `Acuerdo-esperando` y `Pedido-pago`. Se corrigieron la palomita de verificado y el pin rojo.

## 6. Secuencia
Datos → providers → hoja del resumen → "Tu pedido" → chat y ruta → pruebas → capturas → documentación.
