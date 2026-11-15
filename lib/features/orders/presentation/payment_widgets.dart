import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/otp_field.dart';
import 'package:musubi_app/features/chat/presentation/chat_format.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/orders/domain/order_models.dart';
import 'package:musubi_app/features/orders/presentation/order_providers.dart';
import 'package:musubi_app/features/orders/presentation/transfer_screen.dart';

// HU-55: los estados del pago dentro de "Tu pedido" / "Tu venta".

String _first(String name) => name.trim().split(RegExp(r'\s+')).first;

/// "Hoy, 9:14 p. m." o "jue 8 oct, 9:14 p. m." (hora del campus).
String _when(DateTime at, DateTime now) {
  final local = at.toLocal();
  final today = DateUtils.isSameDay(local, now.toLocal());
  return today
      ? 'Hoy, ${clockTime(local)}'
      : '${shortDate(local)}, ${clockTime(local)}';
}

/// `Pago-validando` (quien compra ya aviso "Ya transferi"): el sello
/// "Pendiente · Validando pago", "Diego está validando tu pago" y "Tu
/// transferencia" con monto, para, banco, referencia y concepto. Si quien vende
/// dijo "Todavía no me llega", lo dice en ambar y ofrece mandar otra.
class ValidatingView extends ConsumerWidget {
  const new({required this.order, required this.now, super.key});

  final Order order;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.musubi;
    final seller = _first(order.sellerName);
    final notYet = order.transferNotReceivedAt != null;
    final transfer = ref.watch(transferProvider(order.id)).value;
    return Column(
      key: const Key('order-validating'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 18),
        Center(
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: c.warningSoft,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: MusubiIcon(
              MusubiIcons.landmark,
              size: 34,
              strokeWidth: 1.9,
              color: c.warningText,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 5, 12, 5),
            decoration: BoxDecoration(
              color: c.warningSoft,
              borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: [
                MusubiIcon(
                  notYet ? MusubiIcons.triangleAlert : MusubiIcons.clock,
                  size: 14,
                  strokeWidth: 2.2,
                  color: c.warningText,
                ),
                Flexible(
                  child: Text(
                    notYet
                        ? 'Pendiente · No le ha llegado'
                        : 'Pendiente · Validando pago',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MusubiType.style(
                      13,
                      weight: FontWeight.w800,
                      color: c.warningText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          notYet
              ? '$seller todavía no ve tu pago'
              : '$seller está validando tu pago',
          textAlign: TextAlign.center,
          style: MusubiType.style(
            22,
            line: 27,
            weight: FontWeight.w800,
            em: -0.02,
            color: c.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          notYet
              ? 'Revisa que la referencia y el monto estén bien y mándale la '
                    'referencia otra vez, o escríbele con tu comprobante.'
              : 'Le avisamos que ya transferiste. Cuando confirme que le '
                    'llegó, tu pedido pasa a Confirmado.',
          textAlign: TextAlign.center,
          style: MusubiType.style(14.5, line: 21, color: c.textSecondary),
        ),
        const SizedBox(height: 18),
        _DetailCard(
          key: const Key('order-transfer-summary'),
          title: 'Tu transferencia',
          trailing: switch (order.transferReportedAt) {
            final at? => _when(at, now),
            _ => null,
          },
          rows: [
            ('Monto', exactPrice(order.item.totalCents)),
            if (transfer != null) ('Para', transfer.holderName),
            if (transfer != null) ('Banco', transfer.bankName),
            ('Referencia', order.transferReference ?? '—'),
            ('Concepto', order.number),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            MusubiIcon(
              MusubiIcons.shield,
              size: 16,
              strokeWidth: 1.9,
              color: c.textSecondary,
            ),
            Expanded(
              child: Text(
                'Si $seller dice que no le llegó, revisen juntos la referencia '
                'y el comprobante en el chat.',
                style: MusubiType.style(13, line: 18, color: c.textSecondary),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// `Pago-vendedor`: "Ana dice que ya te transfirió", "Debe llegarte $500.00 ·
/// Por validar", "Búscalo en la app de tu banco" (concepto, referencia, de y a
/// tu cuenta enmascarada) y el aviso de confirmar solo con el dinero visible.
class SellerTransferView extends ConsumerWidget {
  const new({required this.order, required this.now, super.key});

  final Order order;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.musubi;
    final buyer = _first(order.buyerName);
    final transfer = ref.watch(transferProvider(order.id)).value;
    // "AR" de "Ana Sofía Ramírez": nombre y ultimo apellido (maqueta).
    final words = order.buyerName.trim().split(RegExp(r'\s+'));
    final initials = [
      words.first,
      if (words.length > 1) words.last,
    ].map((w) => w.isEmpty ? '' : w[0].toUpperCase()).join();
    return Column(
      key: const Key('order-seller-transfer'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        Row(
          spacing: 12,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: c.warningSoft,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: MusubiType.style(
                  16,
                  weight: FontWeight.w800,
                  color: c.warningText,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    '$buyer dice que ya te transfirió',
                    style: MusubiType.style(
                      16,
                      weight: FontWeight.w800,
                      color: c.textPrimary,
                    ),
                  ),
                  Text(
                    [
                      if (order.transferReportedAt case final at?)
                        _when(at, now),
                      order.item.title,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MusubiType.style(
                      12.5,
                      weight: FontWeight.w600,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 14, 14),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      'Debe llegarte',
                      style: MusubiType.style(
                        12.5,
                        weight: FontWeight.w600,
                        color: c.textSecondary,
                      ),
                    ),
                    Text(
                      exactPrice(order.item.totalCents),
                      style: MusubiType.style(
                        30,
                        weight: FontWeight.w800,
                        em: -0.02,
                        color: c.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
                decoration: BoxDecoration(
                  color: c.warningSoft,
                  borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 5,
                  children: [
                    MusubiIcon(
                      MusubiIcons.clock,
                      size: 13,
                      strokeWidth: 2.2,
                      color: c.warningText,
                    ),
                    Text(
                      'Por validar',
                      style: MusubiType.style(
                        12,
                        weight: FontWeight.w800,
                        color: c.warningText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _DetailCard(
          title: 'Búscalo en la app de tu banco',
          rows: [
            ('Concepto', order.number),
            ('Referencia', order.transferReference ?? '—'),
            ('De', order.buyerName),
            if (transfer != null)
              (
                'A tu cuenta',
                '${transfer.bankName.split(' ').first} •••• '
                    '${transfer.clabeLast4}',
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: c.warningSoft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              MusubiIcon(
                MusubiIcons.triangleAlert,
                size: 18,
                color: c.warningText,
              ),
              Expanded(
                child: Text(
                  order.transferNotReceivedAt == null
                      ? 'Confirma solo cuando veas el dinero en tu cuenta. Una '
                            'captura de pantalla no es prueba de pago.'
                      : 'Le avisaste a $buyer que todavía no te llega. Si ya '
                            'lo ves en tu cuenta, confírmalo.',
                  style: MusubiType.style(
                    13.5,
                    line: 19,
                    weight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// La tarjeta con borde de `Pago-validando` y `Pago-vendedor`: titulo, una hora
/// opcional y filas "etiqueta · valor".
class _DetailCard extends StatelessWidget {
  const new({
    required this.title,
    required this.rows,
    this.trailing,
    super.key,
  });

  final String title;
  final String? trailing;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: MusubiType.style(
                    15,
                    weight: FontWeight.w800,
                    color: c.textPrimary,
                  ),
                ),
              ),
              if (trailing case final text?)
                Text(
                  text,
                  style: MusubiType.style(
                    12.5,
                    weight: FontWeight.w600,
                    color: c.textSecondary,
                  ),
                ),
            ],
          ),
          for (final (label, value) in rows)
            Row(
              spacing: 12,
              children: [
                Text(
                  label,
                  style: MusubiType.style(14, color: c.textSecondary),
                ),
                Expanded(
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MusubiType.style(
                      14,
                      weight: FontWeight.w800,
                      color: c.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// La franja verde de `Pedido-entrega` ("Pago validado · $500 / Transferencia ·
/// Ref. 4829173") y de `Pedido-efectivo` ("Pagas en efectivo al recibir / Lleva
/// el monto exacto · $500").
class PaymentBanner extends StatelessWidget {
  const new({required this.order, super.key});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final total = formatPrice(order.item.totalCents);
    final transfer = order.paysTransfer;
    return Container(
      key: const Key('order-payment-banner'),
      padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
      decoration: BoxDecoration(
        color: c.successSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        spacing: 12,
        children: [
          if (transfer)
            MusubiIcon(MusubiIcons.circleCheck, size: 22, color: c.successText)
          else
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: c.background,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: MusubiIcon(
                MusubiIcons.banknote,
                size: 20,
                color: c.successText,
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  transfer
                      ? 'Pago validado · $total'
                      : order.isBuyer
                      ? 'Pagas en efectivo al recibir'
                      : 'Te paga en efectivo',
                  style: MusubiType.style(
                    15,
                    weight: FontWeight.w800,
                    color: c.successText,
                  ),
                ),
                Text(
                  transfer
                      ? 'Transferencia · Ref. ${order.transferReference ?? '—'}'
                      : order.isBuyer
                      ? 'Lleva el monto exacto'
                      : 'Cuenten el dinero juntos',
                  style: MusubiType.style(
                    13,
                    weight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (!transfer)
            Text(
              total,
              style: MusubiType.style(
                22,
                weight: FontWeight.w800,
                em: -0.02,
                color: c.textPrimary,
              ),
            ),
        ],
      ),
    );
  }
}

/// "TU CÓDIGO DE ENTREGA · Solo tú lo ves" (`Pedido-efectivo`): los 4 digitos
/// en cajas y cuando darlo.
class DeliveryCodeCard extends StatelessWidget {
  const new({required this.code, required this.sellerName, super.key});

  final String code;
  final String sellerName;

  @override
  Widget build(BuildContext context) {
    const white = Color(0xFFFFFFFF);
    const muted = Color(0xB3FFFFFF);
    final seller = _first(sellerName);
    return Semantics(
      label: 'Tu código de entrega: ${code.split('').join(' ')}',
      excludeSemantics: true,
      child: Container(
        key: const Key('order-delivery-code'),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'TU CÓDIGO DE ENTREGA',
                    style: MusubiType.style(
                      12,
                      weight: FontWeight.w800,
                      em: 0.08,
                      color: muted,
                    ),
                  ),
                ),
                const MusubiIcon(
                  MusubiIcons.lock,
                  size: 13,
                  strokeWidth: 2.2,
                  color: muted,
                ),
                const SizedBox(width: 4),
                Text(
                  'Solo tú lo ves',
                  style: MusubiType.style(
                    12,
                    weight: FontWeight.w700,
                    color: muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              spacing: 10,
              children: [
                for (final digit in code.split(''))
                  Expanded(
                    child: Container(
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0x14FFFFFF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0x29FFFFFF)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        digit,
                        style: MusubiType.style(
                          32,
                          weight: FontWeight.w800,
                          color: white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Dáselo a $seller solo después de revisar el producto y pagarle. '
              'Al ingresarlo, se completa tu pedido.',
              style: MusubiType.style(
                13.5,
                line: 19,
                weight: FontWeight.w600,
                color: muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Al momento de la entrega" (`Pedido-efectivo`): tres palomitas verdes.
class HandoverChecklist extends StatelessWidget {
  const new({required this.title, super.key});

  /// Lo que se compra ("la calculadora").
  final String title;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final items = [
      'Revisa que el producto funcione',
      'Paguen y cuenten el dinero frente a frente',
      'No compartas el código antes de tener el producto',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Text(
          'Al momento de la entrega',
          style: MusubiType.style(
            15,
            weight: FontWeight.w800,
            color: c.textPrimary,
          ),
        ),
        for (final item in items)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              MusubiIcon(
                MusubiIcons.check,
                size: 16,
                strokeWidth: 2.4,
                color: c.successText,
              ),
              Expanded(
                child: Text(
                  item,
                  style: MusubiType.style(14, line: 19, color: c.textPrimary),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// "Código de entrega" de quien vende (efectivo, confirmado): los 4 digitos
/// que le dicta quien compra y los intentos que quedan.
class DeliveryCodeEntry extends StatelessWidget {
  const new({
    required this.order,
    required this.controller,
    required this.onCompleted,
    super.key,
  });

  final Order order;
  final TextEditingController controller;
  final ValueChanged<String> onCompleted;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final buyer = _first(order.buyerName);
    final left = order.codeAttemptsLeft ?? 5;
    return Container(
      key: const Key('order-code-entry'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Text(
            'Código de entrega',
            style: MusubiType.style(
              15,
              weight: FontWeight.w800,
              color: c.textPrimary,
            ),
          ),
          Text(
            'Cuando $buyer revise el producto y te pague, pídele su código de '
            '4 dígitos y escríbelo aquí: el pedido se completa.',
            style: MusubiType.style(13.5, line: 19, color: c.textSecondary),
          ),
          OtpField(
            key: const Key('order-code-field'),
            controller: controller,
            length: 4,
            onCompleted: onCompleted,
          ),
          Text(
            left == 1 ? 'Te queda 1 intento.' : 'Te quedan $left intentos.',
            style: MusubiType.style(
              12.5,
              weight: FontWeight.w600,
              color: left <= 2 ? c.warningText : c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
