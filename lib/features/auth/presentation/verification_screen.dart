import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/platform/email_inbox.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/css_line_box.dart';
import 'package:musubi_app/core/widgets/feedback_views.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/core/widgets/otp_field.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/core/widgets/top_bar.dart';
import 'package:musubi_app/features/auth/domain/auth_models.dart';
import 'package:musubi_app/features/auth/presentation/auth_layout.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';

/// "Revisa tu correo institucional" (maqueta `Verificacion`, HU-03): seis
/// cajas para el codigo, que se verifica solo al escribir el sexto digito.
class VerificationScreen extends ConsumerStatefulWidget {
  const new({required this.registration, super.key});

  /// Datos del registro; `null` si se llego sin pasar por "Crea tu cuenta".
  final Registration? registration;

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  final _code = TextEditingController();
  Timer? _ticker;
  late DateTime _resendAt =
      widget.registration?.resendAvailableAt ?? DateTime.now().toUtc();
  Duration _remaining = Duration.zero;
  bool _verifying = false;
  bool _verified = false;
  bool _resending = false;
  ApiFailure? _failure;
  Object? _shake;

  @override
  void initState() {
    super.initState();
    _code.addListener(() => setState(() {}));
    _tick();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _tick() {
    final left = _resendAt.difference(ref.read(clockProvider)());
    setState(() => _remaining = left.isNegative ? Duration.zero : left);
  }

  void _snack(
    String message, {
    MusubiIconData icon = MusubiIcons.circleAlert,
    SnackTone tone = SnackTone.warn,
    String? actionLabel,
    VoidCallback? onAction,
  }) => showMusubiSnack(
    ScaffoldMessenger.of(context),
    message,
    icon: icon,
    tone: tone,
    actionLabel: actionLabel,
    onAction: onAction,
    bottomOffset: AuthLayout.actionsHeight,
  );

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final digits = (data?.text ?? '').replaceAll(RegExp(r'\D'), '');
    if (!mounted) return;
    if (digits.length >= 6) {
      _code.text = digits.substring(0, 6);
    } else {
      _snack('No encontramos un código de 6 dígitos para pegar.');
    }
  }

  Future<void> _verify(Registration registration) async {
    if (_verifying) return;
    final missing = 6 - _code.text.length;
    if (missing > 0) {
      setState(() => _shake = Object());
      _snack(
        'Te faltan $missing ${missing == 1 ? 'dígito' : 'dígitos'}',
        actionLabel: 'Pegar código',
        onAction: () => unawaited(_paste()),
      );
      return;
    }
    setState(() {
      _verifying = true;
      _failure = null;
    });
    final session = ref.read(sessionControllerProvider.notifier);
    try {
      final signedIn = await ref
          .read(authRepositoryProvider)
          .confirmCode(email: registration.email, code: _code.text);
      if (!mounted) return;
      setState(() => _verified = true);
      // Primero se navega a la bienvenida (no es pantalla de visitante) y
      // despues se guarda la sesion, para que la guardia no redirija antes.
      context.go(AppRoutes.welcome, extra: signedIn.user);
      await session.signIn(signedIn.tokens);
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _failure = failure;
        _shake = Object();
      });
      if (failure.code == 'auth.invalid_code' ||
          failure.fieldError('code') != null) {
        _snack(failure.fieldError('code') ?? failure.message);
      }
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend(Registration registration) async {
    setState(() {
      _resending = true;
      _failure = null;
    });
    try {
      final next = await ref
          .read(authRepositoryProvider)
          .resendCode(registration.email);
      if (!mounted) return;
      setState(() {
        _resendAt = next;
        _code.clear();
      });
      _tick();
      _snack(
        'Te enviamos un código nuevo',
        icon: MusubiIcons.check,
        tone: SnackTone.success,
      );
    } on ApiFailure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _openInbox() async {
    final opened = await ref.read(emailInboxProvider).open();
    if (!opened && mounted) {
      _snack('No encontramos una app de correo en tu teléfono.');
    }
  }

  String get _countdown {
    final minutes = _remaining.inMinutes;
    final seconds = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final registration = widget.registration;
    final c = context.musubi;
    if (registration == null) {
      return Scaffold(
        body: Column(
          children: [
            MusubiTopBar(onBack: () => context.go(AppRoutes.signUp)),
            Expanded(
              child: EmptyView(
                title: 'Primero crea tu cuenta',
                message:
                    'Escribe tu correo institucional para recibir el código.',
                icon: MusubiIcons.mailCheck,
                actionLabel: 'Crear cuenta',
                onAction: () => context.go(AppRoutes.signUp),
              ),
            ),
          ],
        ),
      );
    }

    final failure = _failure;
    final codeFailure =
        failure != null &&
        (failure.code == 'auth.invalid_code' ||
            failure.fieldError('code') != null);
    final small = MusubiType.style(
      13,
      weight: FontWeight.w600,
      color: c.textSecondary,
    );

    return AuthLayout(
      onBack: () =>
          context.canPop() ? context.pop() : context.go(AppRoutes.signUp),
      trailing: const Eyebrow('Paso 2 de 2'),
      actions: [
        MusubiButton(
          label: 'Verificar correo',
          loading: _verifying || _verified,
          loadingLabel: 'Verificando…',
          onPressed: () => _verify(registration),
        ),
        MusubiButton(
          label: 'Abrir mi correo',
          kind: MusubiButtonKind.quiet,
          height: MusubiSizes.buttonHeightSmall,
          icon: MusubiIcons.externalLink,
          iconSize: 17,
          foreground: c.textPrimary,
          fontSize: 14,
          gap: 6,
          onPressed: _openInbox,
        ),
      ],
      children: [
        AuthHeading(
          top: 6,
          gap: 8,
          size: 26,
          title: 'Revisa tu correo institucional',
          leading: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: c.brandSoft,
                borderRadius: BorderRadius.circular(MusubiSizes.radiusButton),
              ),
              child: Center(
                child: FloatY(
                  child: MusubiIcon(
                    MusubiIcons.mailCheck,
                    size: 26,
                    strokeWidth: 1.8,
                    color: c.brandText,
                  ),
                ),
              ),
            ),
          ),
          subtitle: TextSpan(
            children: [
              const TextSpan(text: 'Te enviamos un código de 6 dígitos a '),
              TextSpan(
                text: registration.email,
                style: TextStyle(
                  color: c.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CssLineBox(
                fontSize: 13,
                child: Text(
                  'Código de verificación',
                  style: MusubiType.label.copyWith(color: c.textPrimary),
                ),
              ),
              const SizedBox(height: 10),
              OtpField(
                controller: _code,
                fieldKey: const Key('verification-code'),
                autofocus: true,
                verified: _verified,
                shakeTrigger: _shake,
                onCompleted: (_) => unawaited(_verify(registration)),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _remaining > Duration.zero
                        ? Row(
                            key: const Key('resend-countdown'),
                            spacing: 6,
                            children: [
                              MusubiIcon(
                                MusubiIcons.clock,
                                size: 15,
                                color: c.textSecondary,
                              ),
                              CssLineBox(
                                fontSize: 13,
                                child: Text(
                                  'Reenviar código en $_countdown',
                                  style: small,
                                ),
                              ),
                            ],
                          )
                        : Align(
                            alignment: Alignment.centerLeft,
                            child: Pressable(
                              onTap: _resending
                                  ? null
                                  : () => _resend(registration),
                              semanticLabel: 'Reenviar código',
                              builder: (context, _) => SizedBox(
                                height: MusubiSizes.minTouch,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  spacing: 6,
                                  children: [
                                    MusubiIcon(
                                      MusubiIcons.clock,
                                      size: 15,
                                      color: c.brandText,
                                    ),
                                    Text(
                                      'Reenviar código',
                                      style: small.copyWith(color: c.brandText),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: MusubiButton(
                      label: 'Cambiar correo',
                      kind: MusubiButtonKind.link,
                      fontSize: 13.5,
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go(AppRoutes.signUp),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '¿No lo ves? Revisa tu carpeta de spam o correo no deseado.',
                style: MusubiType.style(13, line: 18, color: c.textSecondary),
              ),
              if (failure != null && !codeFailure) ...[
                const SizedBox(height: MusubiSizes.space2),
                InlineMessage(message: failure.message, shakeTrigger: _shake),
              ],
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(MusubiSizes.radiusButton),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: MusubiSizes.space3,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c.background,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Center(
                  child: MusubiIcon(
                    MusubiIcons.graduationCap,
                    size: 19,
                    strokeWidth: 1.9,
                    color: c.brandText,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 3,
                  children: [
                    CssLineBox(
                      fontSize: 14,
                      child: Text(
                        '¿Por qué tu correo de la universidad?',
                        style: MusubiType.style(
                          14,
                          weight: FontWeight.w800,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      'Solo los estudiantes tienen uno. Así Musubi se queda '
                      'solo para tu comunidad.',
                      style: MusubiType.style(
                        13,
                        line: 18,
                        color: c.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
