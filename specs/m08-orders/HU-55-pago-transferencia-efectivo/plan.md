# plan.md — HU-55 Pagar un pedido por transferencia o en efectivo (app)

## 1. Componentes
- `lib/features/orders/`:
  - `domain/payment_models.dart`, y el pago nuevo en `order_models.dart` y `order_repository.dart`;
  - `data/http_order_repository.dart` (con `HttpPayoutRepository`);
  - `presentation/transfer_screen.dart`, `payment_widgets.dart`, `payout_account_screen.dart`, `order_payment_screen.dart` y `order_providers.dart`.
- `lib/app/router.dart` (`transfer`, `settingsPayouts`), `lib/core/network/api_paths.dart`, `lib/core/widgets/musubi_icons.dart`, `settings_screen.dart` y `notifications_screen.dart`.

## 2. Decisiones (con su porqué)
- **Transferencia elegida por defecto:** solo si quien vende tiene cuenta, como `Pedido-pago` de la maqueta; si no, efectivo, como antes.
- **"Ver datos para transferir" registra la forma de pago antes de abrir la cuenta:** así la API ya sabe que se paga por transferencia y quien vende ve "pagará por transferencia".
- **CLABE en la tarjeta negra (usuaria):** la maqueta muestra una tarjeta de débito; aquí solo existe la CLABE.
- **Banco de solo lectura:** se llena con los 3 primeros dígitos de la CLABE (los bancos vienen de la API), así no puede contradecirla.
- **El código lo escribe quien vende (`OtpField`, 4 cajas):** al completar los 4 dígitos se envía. Un código equivocado recarga el pedido para mostrar los intentos.
- **Sin intentos o sin código (pedidos de antes):** los dos botones de HU-24.
- **Avisos redundantes:** con la franja verde, el aviso gris solo sale si dice algo más.

## 3. Excepciones al stack
Ninguna.

## 4. Guardarraíles
- La CLABE completa solo llega en `GET /orders/{id}/transfer` para quien compra; `Cuenta-pagos` nunca la recibe.
- `Clipboard` solo con lo que la persona toca ("Copiar").

## 5. Validación
`flutter test` (ver `spec.md` → Tests), capturas contra la maqueta y prueba en el celular (T5).

## 6. Secuencia
T1 → T2 → T3 → T5.
