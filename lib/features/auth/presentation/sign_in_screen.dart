import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/feedback_views.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_text_field.dart';
import 'package:musubi_app/features/auth/domain/auth_models.dart';
import 'package:musubi_app/features/auth/presentation/account_gate.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';

/// Se llega a "Iniciar sesion" despues de cambiar la contrasena (HU-56).
class PasswordChanged {
  const new(this.email);

  final String email;
}

/// "Hola de nuevo" (maqueta `Iniciar-sesion` / `Iniciar-sesion-error`,
/// HU-02). Al entrar, la guardia del router lleva a `?desde=` o a Inicio.
class SignInScreen extends ConsumerStatefulWidget {
  const new({this.passwordChanged, super.key});

  /// Aviso de "Tu contrasena cambio" y correo ya escrito.
  final PasswordChanged? passwordChanged;

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  late final _email = TextEditingController(
    text: widget.passwordChanged?.email,
  );
  final _password = TextEditingController();
  bool _submitting = false;
  ApiFailure? _failure;

  @override
  void initState() {
    super.initState();
    for (final controller in [_email, _password]) {
      controller.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_submitting &&
      _email.text.trim().isNotEmpty &&
      _password.text.isNotEmpty;

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _failure = null;
    });
    final session = ref.read(sessionControllerProvider.notifier);
    try {
      final signedIn = await ref
          .read(authRepositoryProvider)
          .signIn(email: _email.text, password: _password.text);
      // La guardia saca de esta pantalla de visitante hacia `?desde=`.
      await session.signIn(signedIn.tokens);
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      if (failure.code == 'auth.email_not_verified') {
        await _goVerify();
      } else {
        setState(() => _failure = failure);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Cuenta sin verificar: se manda un codigo nuevo y se va a "Verificacion".
  Future<void> _goVerify() async {
    final email = _email.text.trim().toLowerCase();
    final now = ref.read(clockProvider)();
    DateTime resendAt;
    try {
      resendAt = await ref.read(authRepositoryProvider).resendCode(email);
    } on ApiFailure catch (failure) {
      // Si ya se pidio uno hace menos de 60 s, sirve el que llego.
      if (failure.code != 'auth.resend_too_soon') {
        if (mounted) setState(() => _failure = failure);
        return;
      }
      resendAt = now.add(const Duration(seconds: 60));
    }
    if (!mounted) return;
    unawaited(
      context.push(
        AppRoutes.verification,
        extra: Registration(
          email: email,
          codeExpiresAt: now.add(const Duration(minutes: 10)),
          resendAvailableAt: resendAt,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final c = context.musubi;
    final failure = _failure;
    final wrongCredentials = failure?.code == 'auth.invalid_credentials';

    return Scaffold(
      appBar: AppBar(
        // Si se llego con go (guardia u hoja "Crea tu cuenta") no hay pila:
        // la X vuelve a donde estaba.
        leading: context.canPop() ? null : const ExitToExploreButton(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            MusubiSizes.gutter,
            0,
            MusubiSizes.gutter,
            MusubiSizes.space8,
          ),
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Hola de nuevo', style: textTheme.headlineMedium),
                const SizedBox(height: MusubiSizes.space1),
                Text(
                  'Entra con tu correo institucional.',
                  style: textTheme.bodyLarge,
                ),
                const SizedBox(height: MusubiSizes.space6),
                if (widget.passwordChanged != null && failure == null) ...[
                  const InlineMessage(
                    key: Key('signin-password-changed'),
                    kind: InlineMessageKind.success,
                    title: 'Listo, tu contraseña cambió',
                    message: 'Entra con la nueva en todos tus dispositivos.',
                  ),
                  const SizedBox(height: MusubiSizes.space4),
                ],
                if (failure != null && failure.fieldErrors.isEmpty) ...[
                  InlineMessage(
                    key: const Key('signin-error'),
                    title: 'No pudimos iniciar sesión',
                    message: failure.message,
                  ),
                  const SizedBox(height: MusubiSizes.space4),
                ],
                MusubiTextField(
                  label: 'Correo institucional',
                  fieldKey: const Key('signin-email'),
                  controller: _email,
                  hint: 'tu.nombre@uttt.edu.mx',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  errorText: failure?.fieldError('email'),
                ),
                const SizedBox(height: MusubiSizes.space4),
                MusubiTextField(
                  label: 'Contraseña',
                  fieldKey: const Key('signin-password'),
                  controller: _password,
                  obscure: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) {
                    if (_canSubmit) unawaited(_submit());
                  },
                  errorText: wrongCredentials
                      ? 'Revisa mayúsculas, minúsculas y números.'
                      : failure?.fieldError('password'),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: MusubiButton(
                    label: '¿Olvidaste tu contraseña?',
                    kind: MusubiButtonKind.text,
                    onPressed: () => context.push(
                      AppRoutes.forgotPassword,
                      extra: _email.text.trim(),
                    ),
                  ),
                ),
                const SizedBox(height: MusubiSizes.space4),
                MusubiButton(
                  label: 'Iniciar sesión',
                  loading: _submitting,
                  onPressed: _canSubmit ? _submit : null,
                ),
                const SizedBox(height: MusubiSizes.space3),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '¿Eres nuevo en Musubi?',
                      style: textTheme.bodyMedium?.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                    MusubiButton(
                      label: 'Crea tu cuenta',
                      kind: MusubiButtonKind.text,
                      onPressed: () => context.push(AppRoutes.signUp),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
