import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/return_path.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/feedback_views.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_logo.dart';
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/core/widgets/musubi_text_field.dart';
import 'package:musubi_app/features/auth/domain/auth_models.dart';
import 'package:musubi_app/features/auth/presentation/auth_layout.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';

/// Se llega a "Iniciar sesion" despues de cambiar la contrasena (HU-56).
class PasswordChanged {
  const new(this.email);

  final String email;
}

/// "Hola de nuevo" (maqueta `Iniciar-sesion` / `Iniciar-sesion-error`,
/// HU-02). Al entrar, la guardia del router lleva a `?desde=` o a Inicio y
/// un aviso breve lo confirma.
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
  final _passwordFocus = FocusNode();
  bool _submitting = false;
  ApiFailure? _failure;

  /// Campos vacios al intentar entrar.
  String? _emailMissing;
  String? _passwordMissing;
  Object? _attempt;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final attempt = Object();
    setState(() {
      _attempt = attempt;
      _failure = null;
      _emailMissing = _email.text.trim().isEmpty
          ? 'Escribe tu correo institucional.'
          : null;
      _passwordMissing = _password.text.isEmpty
          ? 'Escribe tu contraseña.'
          : null;
    });
    if (_emailMissing != null || _passwordMissing != null) return;

    setState(() => _submitting = true);
    final session = ref.read(sessionControllerProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final returning =
        AppRoutes.safeReturn(
          GoRouterState.of(context)
                  .uri
                  .queryParameters[AppRoutes.returnParam] ??
              ref.read(returnPathProvider),
        ) !=
        AppRoutes.home;
    try {
      final signedIn = await ref
          .read(authRepositoryProvider)
          .signIn(email: _email.text, password: _password.text);
      // La guardia saca de esta pantalla de visitante hacia `?desde=`.
      await session.signIn(signedIn.tokens);
      if (!mounted) return;
      showMusubiSnack(
        messenger,
        returning
            ? 'Listo, ya entraste. Te regresamos a donde estabas.'
            : '¡Hola, ${signedIn.user.firstName}! Ya estás dentro de Musubi.',
        icon: returning ? MusubiIcons.undo2 : MusubiIcons.check,
      );
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      if (failure.code == 'auth.email_not_verified') {
        await _goVerify();
      } else {
        setState(() => _failure = failure);
        if (failure.code == 'auth.invalid_credentials') {
          _passwordFocus.requestFocus();
          _password.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _password.text.length,
          );
        }
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
    final failure = _failure;
    final wrongCredentials = failure?.code == 'auth.invalid_credentials';
    final banner = failure != null && failure.fieldErrors.isEmpty;

    return AuthLayout(
      onBack: () => leaveAuth(context, ref),
      actions: [
        MusubiButton(
          label: 'Iniciar sesión',
          loading: _submitting,
          loadingLabel: 'Entrando…',
          onPressed: _submit,
        ),
        AuthFooterLink(
          question: '¿Eres nuevo en Musubi?',
          label: 'Crea tu cuenta',
          onTap: () => context.push(AppRoutes.signUp),
        ),
      ],
      children: [
        const AuthHeading(
          title: 'Hola de nuevo',
          subtitle: TextSpan(text: 'Entra con tu correo institucional.'),
          leading: Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: MusubiRings(height: 35),
          ),
        ),
        if (widget.passwordChanged != null && failure == null)
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: InlineMessage(
              key: Key('signin-password-changed'),
              kind: InlineMessageKind.success,
              title: 'Listo, tu contraseña cambió',
              message: 'Entra con la nueva en todos tus dispositivos.',
            ),
          ),
        if (banner)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: InlineMessage(
              key: const Key('signin-error'),
              title: 'No pudimos iniciar sesión',
              message: wrongCredentials
                  ? 'El correo o la contraseña no coinciden. Revísalos e '
                        'inténtalo otra vez.'
                  : failure.message,
              shakeTrigger: _attempt,
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: MusubiSizes.space4,
              children: [
                MusubiTextField(
                  label: 'Correo institucional',
                  fieldKey: const Key('signin-email'),
                  controller: _email,
                  hint: 'tu.nombre@uttt.edu.mx',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  errorText: _emailMissing ?? failure?.fieldError('email'),
                  shakeTrigger: _attempt,
                ),
                MusubiTextField(
                  label: 'Contraseña',
                  fieldKey: const Key('signin-password'),
                  controller: _password,
                  focusNode: _passwordFocus,
                  obscure: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) {
                    if (!_submitting) unawaited(_submit());
                  },
                  errorText:
                      _passwordMissing ??
                      (wrongCredentials
                          ? 'Revisa mayúsculas, minúsculas y números.'
                          : failure?.fieldError('password')),
                  shakeTrigger: _attempt,
                ),
                Transform.translate(
                  offset: const Offset(0, -6),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: MusubiButton(
                      label: '¿Olvidaste tu contraseña?',
                      kind: MusubiButtonKind.link,
                      onPressed: () => context.push(
                        AppRoutes.forgotPassword,
                        extra: _email.text.trim(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
