# plan.md — HU-24 Aceptar y actualizar mis pedidos (app)

## 1. Componentes
- `lib/features/orders/domain/`:
  - `order_models.dart`: `CancelReason`, `OrderCancellation`, los campos nuevos de `Order` y `copyWith`.
  - `order_repository.dart`: tres métodos.
- `lib/features/orders/data/http_order_repository.dart`: las tres rutas y el mapeo de `handover` y `cancellation`.
- `lib/features/orders/presentation/order_payment_screen.dart`: acciones, aviso, nota y hoja de motivos.
- `lib/core/network/api_paths.dart`, `lib/core/widgets/musubi_icons.dart` (`circleX`) y `lib/features/notifications/presentation/notifications_screen.dart` (íconos).
- `test/helpers/fake_orders.dart`: las acciones del fake, con un fallo por acción.

## 2. Decisiones
- **Una sola pantalla para las dos partes.** "Tu pedido" y "Tu venta" ya comparten `OrderPaymentScreen` (HU-23). Una pantalla aparte para quien vende duplicaría el stepper y la tarjeta.
- **Elegir el motivo cancela.** Es igual que en "Reportar un problema": la opción se marca y la hoja se cierra 160 ms después. La hoja se titula "Rechazar pedido" o "Cancelar pedido", así que no hace falta una segunda confirmación.
- **"Aceptar pedido" atenuado, no oculto, sin pago.** Así quien vende ve qué falta. La API también lo rechaza (`orders.payment_missing`).
- **El texto del motivo vive en la app.** La API guarda solo el código (lista cerrada), así que la app puede cambiar el texto sin migrar datos.

## 3. Excepciones al stack
Ninguna.

## 4. Guardarraíles
- Cada acción bloquea las demás mientras corre, para no mandar dos toques.
- Los mensajes de error son los de la API.

## 5. Validación
- `flutter test` (datos y widgets) y las capturas de las tres escenas en claro y oscuro.
- Prueba en el celular con dos cuentas, cuando la API `alpha.20` esté desplegada:
  1. Pedir, pagar en efectivo y aceptar.
  2. Confirmar la entrega desde las dos cuentas.
  3. Revisar los avisos push y que la publicación aparezca vendida.

## 6. Secuencia
Dominio y repositorio → fake → pantalla → avisos → pruebas → capturas → docs.
