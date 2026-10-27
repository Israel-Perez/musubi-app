import 'dart:async';

import 'package:flutter/material.dart';
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
import 'package:musubi_app/core/widgets/otp_field.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/core/widgets/top_bar.dart';
import 'package:musubi_app/features/auth/presentation/auth_layout.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/auth/presentation/password_rules.dart';
import 'package:musubi_app/features/auth/presentation/sign_in_screen.dart';

/// "Recupera tu cuenta" (HU-56): correo → codigo de 6 digitos + contrasena
/// nueva. La maqueta solo trae el enlace; las pantallas siguen el estilo de
/// `Registro` y `Verificacion`.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const new({this.email, super.key});

  /// Correo ya escrito en "Iniciar sesion".
  final String? email;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  late final _email = TextEditingController(text: widget.email);
  final _code = TextEditingController();
  final _password = TextEditingController();
  Timer? _ticker;
  DateTime? _resendAt;
  Duration _remaining = Duration.zero;
  bool _busy = false;
  ApiFailure? _failure;
  bool _emailMissing = false;
  bool _passwordWeak = false;
  Object? _attempt;

  bool get _codeSent => _resendAt != null;

  @override
  void initState() {
    super.initState();
    for (final controller in [_email, _code, _password]) {
      controller.addListener(() => setState(() {}));
    }
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  void _tick() {
    final resendAt = _resendAt;
    if (resendAt == null) return;
    final left = resendAt.difference(ref.read(clockProvider)());
    setState(() => _remaining = left.isNegative ? Duration.zero : left);
  }

  void _snack(
    String message, {
    MusubiIconData icon = MusubiIcons.circleAlert,
    SnackTone tone = SnackTone.warn,
  }) => showMusubiSnack(
    ScaffoldMessenger.of(context),
    message,
    icon: icon,
    tone: tone,
    bottomOffset: AuthLayout.actionsHeight,
  );

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      await action();
    } on ApiFailure catch (failure) {
      if (mounted) {
        setState(() {
          _failure = failure;
          _attempt = Object();
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendCode({bool again = false}) async {
    if (!again) {
      setState(() {
        _attempt = Object();
        _emailMissing = _email.text.trim().isEmpty;
      });
      if (_emailMissing) return;
    }
    await _run(() async {
      final next = await ref
          .read(authRepositoryProvider)
          .requestPasswordReset(_email.text);
      if (!mounted) return;
      setState(() {
        _resendAt = next;
        _code.clear();
      });
      _tick();
      if (again) {
        _snack(
          'Te enviamos un código nuevo',
          icon: MusubiIcons.check,
          tone: SnackTone.success,
        );
      }
    });
  }

  Future<void> _save() async {
    final missing = 6 - _code.text.length;
    setState(() {
      _attempt = Object();
      _passwordWeak = !PasswordRules.isValid(_password.text);
    });
    if (missing > 0) {
      _snack('Te faltan $missing ${missing == 1 ? 'dígito' : 'dígitos'}');
      return;
    }
    if (_passwordWeak) {
      _snack('Tu contraseña necesita 8 caracteres, letras y números');
      return;
    }
    await _run(() async {
      final email = _email.text.trim().toLowerCase();
      await ref
          .read(authRepositoryProvider)
          .resetPassword(
            email: email,
            code: _code.text,
            newPassword: _password.text,
          );
      if (!mounted) return;
      context.go(AppRoutes.signIn, extra: PasswordChanged(email));
    });
  }

  void _changeEmail() => setState(() {
    _resendAt = null;
    _failure = null;
    _passwordWeak = false;
    _code.clear();
    _password.clear();
  });

  String get _countdown {
    final minutes = _remaining.inMinutes;
    final seconds = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final failure = _failure;
    final codeError = switch (failure?.code) {
      'auth.invalid_code' => failure!.message,
      _ => failure?.fieldError('code'),
    };
    final passwordError = switch (failure?.code) {
      'auth.weak_password' => failure!.message,
      _ when _passwordWeak && !PasswordRules.isValid(_password.text) =>
        'Usa al menos 8 caracteres, con letras y números.',
      _ => failure?.fieldError('newPassword'),
    };
    final showBanner =
        failure != null &&
        codeError == null &&
        passwordError == null &&
        failure.fieldError('email') == null;

    return _codeSent
        ? _codeStep(context, codeError, passwordError, showBanner)
        : _emailStep(context, showBanner);
  }

  Widget _emailStep(BuildContext context, bool showBanner) => AuthLayout(
    onBack: () =>
        context.canPop() ? context.pop() : context.go(AppRoutes.signIn),
    actions: [
      MusubiButton(
        label: 'Enviar código',
        loading: _busy,
        loadingLabel: 'Enviando…',
        onPressed: _sendCode,
      ),
      AuthFooterLink(
        question: '¿Ya la recordaste?',
        label: 'Inicia sesión',
        onTap: () =>
            context.canPop() ? context.pop() : context.go(AppRoutes.signIn),
      ),
    ],
    children: [
      const AuthHeading(
        title: 'Recupera tu cuenta',
        leading: Eyebrow('Paso 1 de 2'),
        subtitle: TextSpan(
          text:
              'Escribe tu correo institucional y te enviaremos un código para '
              'crear una contraseña nueva.',
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: MusubiSizes.space4,
          children: [
            MusubiTextField(
              label: 'Correo institucional',
              fieldKey: const Key('forgot-email'),
              controller: _email,
              hint: 'tu.nombre@uttt.edu.mx',
              prefixIcon: MusubiIcons.mail,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              onSubmitted: (_) {
                if (!_busy) unawaited(_sendCode());
              },
              errorText: _emailMissing && _email.text.trim().isEmpty
                  ? 'Escribe tu correo institucional.'
                  : _failure?.fieldError('email'),
              shakeTrigger: _attempt,
            ),
            if (showBanner)
              InlineMessage(message: _failure!.message, shakeTrigger: _attempt),
          ],
        ),
      ),
    ],
  );

  Widget _codeStep(
    BuildContext context,
    String? codeError,
    String? passwordError,
    bool showBanner,
  ) {
    final c = context.musubi;
    final small = MusubiType.style(
      13,
      weight: FontWeight.w600,
      color: c.textSecondary,
    );
    return AuthLayout(
      onBack: _busy ? null : _changeEmail,
      trailing: const Eyebrow('Paso 2 de 2'),
      actions: [
        MusubiButton(
          label: 'Guardar contraseña',
          loading: _busy,
          loadingLabel: 'Guardando…',
          onPressed: _save,
        ),
        AuthFooterLink(
          question: '¿Ya la recordaste?',
          label: 'Inicia sesión',
          onTap: () => context.go(AppRoutes.signIn),
        ),
      ],
      children: [
        AuthHeading(
          top: 6,
          gap: 8,
          size: 26,
          title: 'Crea tu contraseña nueva',
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
                child: MusubiIcon(
                  MusubiIcons.lock,
                  size: 26,
                  strokeWidth: 1.8,
                  color: c.brandText,
                ),
              ),
            ),
          ),
          // No confirma que la cuenta exista (la API responde igual).
          subtitle: TextSpan(
            children: [
              const TextSpan(text: 'Si '),
              TextSpan(
                text: _email.text.trim(),
                style: TextStyle(
                  color: c.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const TextSpan(
                text:
                    ' tiene cuenta en Musubi, te enviamos un código de 6 '
                    'dígitos.',
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
          child: Column(
            key: const Key('forgot-sent'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Código',
                style: MusubiType.label.copyWith(color: c.textPrimary),
              ),
              const SizedBox(height: 10),
              OtpField(
                controller: _code,
                fieldKey: const Key('forgot-code'),
                autofocus: true,
                shakeTrigger: codeError == null ? null : _attempt,
              ),
              if (codeError != null) ...[
                const SizedBox(height: 8),
                FieldMessage(text: codeError),
              ],
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: _remaining > Duration.zero
                        ? Row(
                            key: const Key('forgot-countdown'),
                            spacing: 6,
                            children: [
                              MusubiIcon(
                                MusubiIcons.clock,
                                size: 15,
                                color: c.textSecondary,
                              ),
                              Text(
                                'Reenviar código en $_countdown',
                                style: small,
                              ),
                            ],
                          )
                        : Align(
                            alignment: Alignment.centerLeft,
                            child: Pressable(
                              onTap: _busy
                                  ? null
                                  : () => _sendCode(again: true),
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
                      onPressed: _busy ? null : _changeEmail,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              MusubiTextField(
                label: 'Contraseña nueva',
                fieldKey: const Key('forgot-password'),
                controller: _password,
                obscure: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                errorText: passwordError,
                shakeTrigger: _attempt,
                footer: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: PasswordRuleList(password: _password.text),
                ),
              ),
              const SizedBox(height: MusubiSizes.space4),
              Text(
                'Al guardarla, cerramos tu sesión en todos tus dispositivos.',
                style: MusubiType.style(13, line: 18, color: c.textSecondary),
              ),
              if (showBanner) ...[
                const SizedBox(height: MusubiSizes.space3),
                InlineMessage(
                  message: _failure!.message,
                  shakeTrigger: _attempt,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
