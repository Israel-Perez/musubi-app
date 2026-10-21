import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/feedback_views.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_text_field.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/auth/presentation/password_rules.dart';
import 'package:musubi_app/features/auth/presentation/sign_in_screen.dart';

/// "Recupera tu cuenta" (HU-56): correo → codigo de 6 digitos + contrasena
/// nueva. La maqueta solo trae el enlace; las pantallas siguen el estilo de
/// `Verificacion`.
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
  String? _notice;

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

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _failure = null;
      _notice = null;
    });
    try {
      await action();
    } on ApiFailure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendCode({bool again = false}) => _run(() async {
    final next = await ref
        .read(authRepositoryProvider)
        .requestPasswordReset(_email.text);
    if (!mounted) return;
    setState(() {
      _resendAt = next;
      _code.clear();
      if (again) _notice = 'Te enviamos un código nuevo.';
    });
    _tick();
  });

  Future<void> _save() => _run(() async {
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

  void _changeEmail() => setState(() {
    _resendAt = null;
    _failure = null;
    _notice = null;
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
    final textTheme = Theme.of(context).textTheme;
    final failure = _failure;
    final codeError = switch (failure?.code) {
      'auth.invalid_code' => failure!.message,
      _ => failure?.fieldError('code'),
    };
    final passwordError = switch (failure?.code) {
      'auth.weak_password' => failure!.message,
      _ => failure?.fieldError('newPassword'),
    };
    final showBanner =
        failure != null &&
        codeError == null &&
        passwordError == null &&
        failure.fieldError('email') == null;

    final children = _codeSent
        ? <Widget>[
            Text('PASO 2 DE 2', style: textTheme.labelSmall),
            const SizedBox(height: MusubiSizes.space2),
            Text('Crea tu contraseña nueva', style: textTheme.headlineMedium),
            const SizedBox(height: MusubiSizes.space2),
            // No confirma que la cuenta exista (la API responde igual).
            Text(
              'Si ${_email.text.trim()} tiene cuenta en Musubi, te enviamos '
              'un código de 6 dígitos.',
              key: const Key('forgot-sent'),
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: MusubiSizes.space6),
            MusubiTextField(
              label: 'Código',
              fieldKey: const Key('forgot-code'),
              controller: _code,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.oneTimeCode],
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              errorText: codeError,
            ),
            Row(
              children: [
                if (_remaining > Duration.zero)
                  Text(
                    'Reenviar código en $_countdown',
                    key: const Key('forgot-countdown'),
                    style: textTheme.bodyMedium,
                  )
                else
                  MusubiButton(
                    label: 'Reenviar código',
                    kind: MusubiButtonKind.text,
                    onPressed: _busy ? null : () => _sendCode(again: true),
                  ),
                const Spacer(),
                MusubiButton(
                  label: 'Cambiar correo',
                  kind: MusubiButtonKind.text,
                  onPressed: _busy ? null : _changeEmail,
                ),
              ],
            ),
            const SizedBox(height: MusubiSizes.space2),
            MusubiTextField(
              label: 'Contraseña nueva',
              fieldKey: const Key('forgot-password'),
              controller: _password,
              obscure: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              errorText: passwordError,
            ),
            const SizedBox(height: MusubiSizes.space2),
            PasswordRuleList(password: _password.text),
            if (_notice != null)
              InlineMessage(kind: InlineMessageKind.success, message: _notice!),
            if (showBanner) ...[
              const SizedBox(height: MusubiSizes.space2),
              InlineMessage(message: failure.message),
            ],
            const SizedBox(height: MusubiSizes.space4),
            Text(
              'Al guardarla, cerramos tu sesión en todos tus dispositivos.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: MusubiSizes.space6),
            MusubiButton(
              label: 'Guardar contraseña',
              loading: _busy,
              onPressed:
                  !_busy &&
                      _code.text.length == 6 &&
                      PasswordRules.isValid(_password.text)
                  ? _save
                  : null,
            ),
          ]
        : <Widget>[
            Text('PASO 1 DE 2', style: textTheme.labelSmall),
            const SizedBox(height: MusubiSizes.space2),
            Text('Recupera tu cuenta', style: textTheme.headlineMedium),
            const SizedBox(height: MusubiSizes.space2),
            Text(
              'Escribe tu correo institucional y te enviaremos un código para '
              'crear una contraseña nueva.',
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: MusubiSizes.space6),
            MusubiTextField(
              label: 'Correo institucional',
              fieldKey: const Key('forgot-email'),
              controller: _email,
              hint: 'tu.nombre@uttt.edu.mx',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              errorText: failure?.fieldError('email'),
            ),
            if (showBanner) ...[
              const SizedBox(height: MusubiSizes.space2),
              InlineMessage(message: failure.message),
            ],
            const SizedBox(height: MusubiSizes.space6),
            MusubiButton(
              label: 'Enviar código',
              loading: _busy,
              onPressed: !_busy && _email.text.trim().isNotEmpty
                  ? _sendCode
                  : null,
            ),
          ];

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            MusubiSizes.gutter,
            0,
            MusubiSizes.gutter,
            MusubiSizes.space8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}
