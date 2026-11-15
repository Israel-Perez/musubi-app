import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/feedback_views.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_panel.dart';
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/core/widgets/musubi_text_field.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/orders/domain/order_models.dart';
import 'package:musubi_app/features/orders/domain/payment_models.dart';
import 'package:musubi_app/features/orders/presentation/order_providers.dart';

/// "Paga por transferencia" (`Pago-transferencia`, HU-55): el monto exacto, la
/// cuenta de quien vende (banco, titular y CLABE, verificada) y el concepto,
/// cada uno con "Copiar"; luego "Captura la referencia" y "Enviar referencia a
/// Diego". Musubi no procesa el dinero (D-01).
/// NOTE (HU-55): "Adjuntar comprobante · opcional" (con almacenamiento
/// privado; decision de la usuaria del 15-Nov-2026).
class TransferScreen extends ConsumerStatefulWidget {
  const new({required this.orderId, super.key});

  final String orderId;

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  final _reference = TextEditingController();
  bool _sending = false;
  String? _error;

  /// Referencia o clave de rastreo: letras y numeros, de 4 a 30 (como la API).
  static final _valid = RegExp(r'^[A-Za-z0-9-]{4,30}$');

  String get _clean => _reference.text.replaceAll(' ', '');

  @override
  void initState() {
    super.initState();
    _reference.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _reference.dispose();
    super.dispose();
  }

  void _copy(String label, String value) {
    unawaited(Clipboard.setData(ClipboardData(text: value)));
    showMusubiSnack(
      ScaffoldMessenger.of(context),
      '$label copiado',
      icon: MusubiIcons.copy,
    );
  }

  Future<void> _send(Order order) async {
    final router = GoRouter.of(context);
    setState(() => _sending = true);
    try {
      await ref
          .read(orderRepositoryProvider)
          .reportTransfer(order.id, _clean.toUpperCase());
      if (!mounted) return;
      ref
        ..invalidate(orderProvider(order.id))
        ..invalidate(transferProvider(order.id))
        ..invalidate(openOrderProvider(order.conversationId));
      if (router.canPop()) {
        router.pop();
      } else {
        router.go(AppRoutes.order(order.id));
      }
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = failure.message;
      });
    }
  }

  Future<void> _help() => showMusubiPanel<void>(
    context,
    builder: (context) => MusubiPanel(
      title: '¿Cómo pago por transferencia?',
      actions: [
        MusubiButton(
          label: 'Entendido',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
      child: Text(
        'Transfiere el monto exacto desde la app de tu banco a la cuenta que '
        'te mostramos, con el número del pedido como concepto. Luego escribe '
        'la referencia de tu comprobante: le avisamos a quien vende para que '
        'confirme que le llegó. Musubi no cobra comisión ni procesa el dinero.',
        style: MusubiType.style(
          14,
          line: 20,
          color: context.musubi.textSecondary,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final order = ref.watch(orderProvider(widget.orderId));
    final transfer = ref.watch(transferProvider(widget.orderId));
    return Scaffold(
      backgroundColor: c.background,
      body: switch ((order, transfer)) {
        (AsyncData(value: final o), AsyncData(value: final t)) => _body(o, t),
        (AsyncError(:final error), _) ||
        (_, AsyncError(:final error)) => SafeArea(
          child: ErrorView(
            message: error is ApiFailure
                ? error.message
                : 'No pudimos cargar la cuenta para transferir.',
            onRetry: () => ref
              ..invalidate(orderProvider(widget.orderId))
              ..invalidate(transferProvider(widget.orderId)),
          ),
        ),
        _ => const Center(child: MusubiSpinner()),
      },
    );
  }

  Widget _body(Order order, TransferDetails t) {
    final c = context.musubi;
    final seller = _first(order.sellerName);
    final valid = _valid.hasMatch(_clean);
    final bottom = math.max<double>(
      30,
      MediaQuery.viewPaddingOf(context).bottom,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SafeArea(
          bottom: false,
          child: _Header(
            title: 'Paga por transferencia',
            subtitle: 'Pedido #${order.number}',
            onBack: () => context.pop(),
            onHelp: () => unawaited(_help()),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  spacing: 8,
                  children: [
                    _StepNumber(1, color: c.brand),
                    Expanded(
                      child: Text(
                        'Transfiere exactamente',
                        style: MusubiType.style(
                          15,
                          weight: FontWeight.w800,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      exactPrice(t.amountCents),
                      key: const Key('transfer-amount'),
                      style: MusubiType.style(
                        19,
                        weight: FontWeight.w800,
                        em: -0.02,
                        color: c.textPrimary,
                      ),
                    ),
                    _CopyIcon(
                      key: const Key('transfer-copy-amount'),
                      label: 'Copiar el monto',
                      onTap: () => _copy(
                        'Monto',
                        (t.amountCents / 100).toStringAsFixed(2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                AccountCard(
                  key: const Key('transfer-card'),
                  label: 'BANCO RECEPTOR',
                  bankName: t.bankName,
                  number: t.clabe,
                  holderName: t.holderName,
                  badge: 'Verificado',
                  onCopy: () => _copy('CLABE', t.clabeDigits),
                ),
                const SizedBox(height: 10),
                _CopyRow(
                  key: const Key('transfer-concept'),
                  label: 'Concepto · escríbelo tal cual',
                  value: t.concept,
                  onCopy: () => _copy('Concepto', t.concept),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10,
                  children: [
                    MusubiIcon(
                      MusubiIcons.shieldCheck,
                      size: 17,
                      strokeWidth: 1.9,
                      color: c.successText,
                    ),
                    Expanded(
                      child: Text(
                        'Está a nombre de $seller, igual que su perfil '
                        'verificado. No transfieras a cuentas que te pasen por '
                        'chat.',
                        style: MusubiType.style(
                          13,
                          line: 18,
                          weight: FontWeight.w600,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  spacing: 10,
                  children: [
                    _StepNumber(2, color: c.inverse),
                    Text(
                      'Captura la referencia',
                      style: MusubiType.style(
                        15,
                        weight: FontWeight.w800,
                        color: c.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                MusubiTextField(
                  label: 'Referencia',
                  fieldKey: const Key('transfer-reference'),
                  controller: _reference,
                  hint: 'Ej. 4829173',
                  errorText: _error,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [LengthLimitingTextInputFormatter(30)],
                  suffix: valid
                      ? MusubiIcon(
                          MusubiIcons.circleCheck,
                          size: 20,
                          color: c.successText,
                        )
                      : null,
                  footer: Text(
                    'Aparece en tu comprobante como «Referencia» o «Clave de '
                    'rastreo».',
                    style: MusubiType.style(
                      12.5,
                      line: 17,
                      color: c.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: c.background,
            border: Border(top: BorderSide(color: c.border)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, bottom),
            child: MusubiButton(
              key: const Key('transfer-send'),
              label: 'Enviar referencia a $seller',
              loadingLabel: 'Enviando…',
              loading: _sending,
              icon: MusubiIcons.send,
              dimmed: !valid,
              onPressed: valid && !_sending
                  ? () => unawaited(_send(order))
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

String _first(String name) => name.trim().split(RegExp(r'\s+')).first;

/// "$500.00": el monto exacto con centavos (para no transferir de menos).
String exactPrice(int cents) {
  final pesos = formatPrice(cents);
  return '$pesos.${(cents % 100).toString().padLeft(2, '0')}';
}

/// La barra de "Paga por transferencia": titulo y numero del pedido al centro,
/// regresar a la izquierda y ayuda a la derecha.
class _Header extends StatelessWidget {
  const new({
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.onHelp,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    Widget icon(
      MusubiIconData data,
      double size,
      String label,
      VoidCallback onTap,
    ) => Pressable(
      onTap: onTap,
      semanticLabel: label,
      builder: (context, _) => SizedBox.square(
        dimension: MusubiSizes.minTouch,
        child: Center(
          child: MusubiIcon(
            data,
            size: size,
            strokeWidth: 1.9,
            color: c.textPrimary,
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          icon(MusubiIcons.chevronLeft, 24, 'Regresar', onBack),
          Expanded(
            child: Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MusubiType.style(
                    17,
                    weight: FontWeight.w800,
                    color: c.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: MusubiType.style(
                    12,
                    weight: FontWeight.w600,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          icon(MusubiIcons.circleHelp, 22, 'Ayuda', onHelp),
        ],
      ),
    );
  }
}

/// El numero de un paso: circulo de 24 con el numero en blanco.
class _StepNumber extends StatelessWidget {
  const new(this.number, {required this.color});

  final int number;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 24,
    height: 24,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    alignment: Alignment.center,
    child: Text(
      '$number',
      style: MusubiType.style(
        12,
        weight: FontWeight.w800,
        color: context.musubi.onBrand,
      ),
    ),
  );
}

/// El icono rojo de copiar (44 de toque).
class _CopyIcon extends StatelessWidget {
  const new({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    semanticLabel: label,
    builder: (context, _) => SizedBox(
      width: 32,
      height: MusubiSizes.minTouch,
      child: Center(
        child: MusubiIcon(
          MusubiIcons.copy,
          size: 18,
          color: context.musubi.brand,
        ),
      ),
    ),
  );
}

/// Una fila gris con su etiqueta, el valor y "Copiar".
class _CopyRow extends StatelessWidget {
  const new({
    required this.label,
    required this.value,
    required this.onCopy,
    super.key,
  });

  final String label;
  final String value;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  label,
                  style: MusubiType.style(
                    12.5,
                    weight: FontWeight.w600,
                    color: c.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: MusubiType.style(
                    16,
                    weight: FontWeight.w800,
                    em: 0.02,
                    color: c.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Pressable(
            onTap: onCopy,
            semanticLabel: 'Copiar $label',
            builder: (context, _) => SizedBox(
              height: MusubiSizes.minTouch,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 6,
                  children: [
                    MusubiIcon(MusubiIcons.copy, size: 16, color: c.brand),
                    Text(
                      'Copiar',
                      style: MusubiType.style(
                        14,
                        weight: FontWeight.w800,
                        color: c.brand,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// La tarjeta negra de la cuenta (`Pago-transferencia` y `Cuenta-pagos`):
/// banco, la CLABE (completa o enmascarada) con su boton de copiar, el titular
/// y su sello.
class AccountCard extends StatelessWidget {
  const new({
    required this.label,
    required this.bankName,
    required this.number,
    required this.holderName,
    required this.badge,
    this.onCopy,
    super.key,
  });

  final String label;
  final String bankName;
  final String number;
  final String holderName;
  final String badge;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    const white = Color(0xFFFFFFFF);
    const muted = Color(0xB3FFFFFF);
    final eyebrow = MusubiType.style(
      11,
      weight: FontWeight.w800,
      em: 0.08,
      color: muted,
    );
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(0, 8),
            blurRadius: 20,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -10,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x14FFFFFF), width: 10),
              ),
            ),
          ),
          Positioned(
            right: -80,
            top: -10,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: c.brand.withValues(alpha: 0.25),
                  width: 10,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(label, style: eyebrow)),
                    Text('CLABE', style: eyebrow),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  bankName,
                  style: MusubiType.style(
                    17,
                    weight: FontWeight.w800,
                    color: white,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 36,
                  height: 26,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9B45B),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          number,
                          key: const Key('account-card-number'),
                          style: MusubiType.style(
                            20,
                            weight: FontWeight.w800,
                            em: 0.04,
                            color: white,
                          ),
                        ),
                      ),
                    ),
                    if (onCopy case final copy?)
                      Pressable(
                        onTap: copy,
                        semanticLabel: 'Copiar la CLABE',
                        builder: (context, _) => Container(
                          width: MusubiSizes.minTouch,
                          height: MusubiSizes.minTouch,
                          decoration: const BoxDecoration(
                            color: Color(0x1FFFFFFF),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const MusubiIcon(
                            MusubiIcons.copy,
                            size: 17,
                            color: white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('TITULAR DE LA CUENTA', style: eyebrow),
                const SizedBox(height: 2),
                Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: Text(
                        holderName.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MusubiType.style(
                          14.5,
                          weight: FontWeight.w800,
                          color: white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
                      decoration: BoxDecoration(
                        color: const Color(0x1FFFFFFF),
                        borderRadius: BorderRadius.circular(
                          MusubiSizes.radiusChip,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 5,
                        children: [
                          MusubiIcon(
                            MusubiIcons.shieldCheck,
                            size: 13,
                            strokeWidth: 2.2,
                            color: c.brand,
                          ),
                          Text(
                            badge,
                            style: MusubiType.style(
                              12,
                              weight: FontWeight.w800,
                              color: white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
