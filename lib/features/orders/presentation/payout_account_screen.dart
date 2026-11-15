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
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/core/widgets/musubi_text_field.dart';
import 'package:musubi_app/core/widgets/top_bar.dart';
import 'package:musubi_app/features/orders/domain/payment_models.dart';
import 'package:musubi_app/features/orders/presentation/order_providers.dart';
import 'package:musubi_app/features/orders/presentation/transfer_screen.dart';
import 'package:musubi_app/features/profile/presentation/profile_screen.dart';

/// "Cuenta para recibir pagos" (`Cuenta-pagos`, HU-55, desde `Ajustes`): la
/// tarjeta negra con el banco, la CLABE enmascarada y el titular; "Titular de
/// la cuenta" (debe coincidir con el nombre verificado), "Banco" (se llena con
/// los 3 primeros digitos de la CLABE) y "CLABE interbancaria". La API valida
/// y la guarda cifrada; aqui nunca vuelve completa. Decision de la usuaria del
/// 15-Nov-2026: sin el numero de tarjeta de la maqueta.
class PayoutAccountScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<PayoutAccountScreen> createState() =>
      _PayoutAccountScreenState();
}

class _PayoutAccountScreenState extends ConsumerState<PayoutAccountScreen> {
  final _holder = TextEditingController();
  final _clabe = TextEditingController();
  bool _filled = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final field in [_holder, _clabe]) {
      field.addListener(() => setState(() => _error = null));
    }
  }

  @override
  void dispose() {
    _holder.dispose();
    _clabe.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() => _saving = true);
    try {
      await ref
          .read(payoutRepositoryProvider)
          .save(
            holderName: _holder.text.trim(),
            clabe: Clabe.digits(_clabe.text),
          );
      if (!mounted) return;
      ref.invalidate(payoutStatusProvider);
      showMusubiSnack(
        messenger,
        'Listo: te pueden pagar por transferencia.',
        icon: MusubiIcons.circleCheck,
      );
      if (router.canPop()) {
        router.pop();
      } else {
        router.go(AppRoutes.settings);
      }
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = failure.message;
      });
    }
  }

  Future<void> _remove() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(payoutRepositoryProvider).remove();
      if (!mounted) return;
      ref.invalidate(payoutStatusProvider);
      _clabe.clear();
      showMusubiSnack(
        messenger,
        'Quitaste tu cuenta. Te pagarán en efectivo.',
        icon: MusubiIcons.circleCheck,
      );
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      showMusubiSnack(
        messenger,
        failure.message,
        icon: MusubiIcons.circleAlert,
        tone: SnackTone.warn,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final status = ref.watch(payoutStatusProvider);
    final banks = ref.watch(payoutBanksProvider).value ?? const [];
    if (status case AsyncData(:final value) when !_filled) {
      _filled = true;
      _holder.text =
          value.account?.holderName ?? sessionProfile(ref)?.fullName ?? '';
    }
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
        child: switch (status) {
          AsyncData(:final value) => _body(value, banks),
          AsyncError(:final error) => ErrorView(
            message: error is ApiFailure
                ? error.message
                : 'No pudimos cargar tu cuenta.',
            onRetry: () => ref.invalidate(payoutStatusProvider),
          ),
          _ => const Center(child: MusubiSpinner()),
        },
      ),
    );
  }

  Widget _body(PayoutStatus status, List<PayoutBank> banks) {
    final c = context.musubi;
    final account = status.account;
    final digits = Clabe.digits(_clabe.text);
    final typed = digits.length >= 3
        ? banks.where((b) => digits.startsWith(b.code)).firstOrNull
        : null;
    final complete = digits.length == Clabe.length;
    final validClabe = complete && Clabe.isValid(digits);
    final holder = _holder.text.trim();
    final ready =
        status.available && validClabe && holder.length >= 3 && !_saving;
    final bankName = digits.isEmpty
        ? (account?.bankName ?? 'Tu banco')
        : (typed?.name ?? 'Tu banco');
    final last4 = digits.length >= 4
        ? digits.substring(digits.length - 4)
        : (account?.clabeLast4 ?? '····');
    final bottom = math.max<double>(
      30,
      MediaQuery.viewPaddingOf(context).bottom,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MusubiTopBar(
          title: 'Cuenta para recibir pagos',
          onBack: () => context.pop(),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Cuando alguien te compre por transferencia, verá estos '
                  'datos para pagarte directo a tu cuenta.',
                  style: MusubiType.style(15, line: 21, color: c.textSecondary),
                ),
                const SizedBox(height: 16),
                AccountCard(
                  key: const Key('payout-card'),
                  label: 'BANCO',
                  bankName: bankName,
                  number: '•••• •••• •••• $last4',
                  holderName: holder.isEmpty ? 'Tu nombre' : holder,
                  badge: 'A tu nombre',
                ),
                if (!status.available) ...[
                  const SizedBox(height: 14),
                  const InlineMessage(
                    kind: InlineMessageKind.warning,
                    message:
                        'Por ahora no podemos guardar cuentas. Tus compradores '
                        'pueden pagarte en efectivo.',
                  ),
                ],
                const SizedBox(height: 18),
                MusubiTextField(
                  label: 'Titular de la cuenta',
                  fieldKey: const Key('payout-holder'),
                  controller: _holder,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [LengthLimitingTextInputFormatter(80)],
                  footer: const _Hint(
                    'Debe coincidir con tu nombre verificado.',
                  ),
                ),
                const SizedBox(height: 16),
                _ReadOnlyField(
                  key: const Key('payout-bank'),
                  label: 'Banco',
                  value:
                      typed?.name ??
                      (digits.isEmpty ? account?.bankName : null) ??
                      'Se llena con tu CLABE',
                  placeholder:
                      typed == null && (digits.isNotEmpty || account == null),
                ),
                const SizedBox(height: 16),
                MusubiTextField(
                  label: 'CLABE interbancaria',
                  fieldKey: const Key('payout-clabe'),
                  controller: _clabe,
                  hint: account == null
                      ? '18 dígitos'
                      : 'Tu CLABE termina en ${account.clabeLast4}',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(Clabe.length),
                  ],
                  errorText:
                      _error ??
                      (complete && !validClabe
                          ? 'Revisa tu CLABE: un dígito no coincide.'
                          : null),
                  suffix: validClabe
                      ? MusubiIcon(
                          MusubiIcons.circleCheck,
                          size: 20,
                          color: c.successText,
                        )
                      : null,
                  footer: const _Hint(
                    '18 dígitos. La encuentras en la app de tu banco.',
                  ),
                ),
                if (account != null) ...[
                  const SizedBox(height: 18),
                  MusubiButton(
                    key: const Key('payout-remove'),
                    label: 'Quitar cuenta',
                    kind: MusubiButtonKind.quiet,
                    height: 44,
                    foreground: c.error,
                    onPressed: () => unawaited(_remove()),
                  ),
                ],
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
              key: const Key('payout-save'),
              label: 'Guardar cuenta',
              loadingLabel: 'Guardando…',
              loading: _saving,
              dimmed: !ready,
              onPressed: ready ? () => unawaited(_save()) : null,
            ),
          ),
        ),
      ],
    );
  }
}

/// La ayuda gris bajo un campo.
class _Hint extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(
      text,
      style: MusubiType.style(
        12.5,
        line: 17,
        color: context.musubi.textSecondary,
      ),
    ),
  );
}

/// "Banco": la caja de un campo, sin escribir, con la flecha de la maqueta.
class _ReadOnlyField extends StatelessWidget {
  const new({
    required this.label,
    required this.value,
    required this.placeholder,
    super.key,
  });

  final String label;
  final String value;
  final bool placeholder;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Text(
            label,
            style: MusubiType.style(
              13,
              weight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.border, width: 1.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: MusubiType.style(
                      16,
                      color: placeholder ? c.textTertiary : c.textPrimary,
                    ),
                  ),
                ),
                MusubiIcon(MusubiIcons.chevronDown, size: 20, color: c.chevron),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
