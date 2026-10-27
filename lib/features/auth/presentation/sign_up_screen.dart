import 'dart:async';

import 'package:flutter/gestures.dart';
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
import 'package:musubi_app/core/widgets/musubi_controls.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/core/widgets/musubi_text_field.dart';
import 'package:musubi_app/core/widgets/shake.dart';
import 'package:musubi_app/core/widgets/top_bar.dart';
import 'package:musubi_app/features/auth/domain/auth_models.dart';
import 'package:musubi_app/features/auth/presentation/auth_layout.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/auth/presentation/password_rules.dart';

/// "Crea tu cuenta" (maqueta `Registro` / `Registro-error`, HU-01 y HU-47).
/// Como en la maqueta, "Crear cuenta" siempre se puede tocar: si falta algo,
/// lo dice (sacude el campo y avisa). Con un correo que no es de la
/// universidad se ve gris, como en `Registro-error`, y al tocarlo sacude el
/// aviso y vuelve al correo.
class SignUpScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

sealed class _CampusCheck {
  const new();
}

final class _CampusIdle extends _CampusCheck {
  const new();
}

final class _CampusChecking extends _CampusCheck {
  const new();
}

final class _CampusFound extends _CampusCheck {
  const new(this.campus);
  final Campus campus;
}

final class _CampusRejected extends _CampusCheck {
  const new();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _email = TextEditingController();
  final _name = TextEditingController();
  final _password = TextEditingController();
  final _emailFocus = FocusNode();
  Timer? _debounce;
  _CampusCheck _campus = const _CampusIdle();
  bool _consent = false;
  bool _submitting = false;
  ApiFailure? _failure;

  /// Correo o nombre vacios y contrasena que no cumple al tocar "Crear
  /// cuenta".
  bool _emailMissing = false;
  bool _nameMissing = false;
  bool _passwordWeak = false;
  Object? _attempt;
  Object? _consentShake;

  @override
  void initState() {
    super.initState();
    for (final controller in [_name, _password]) {
      controller.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _email.dispose();
    _emailFocus.dispose();
    _name.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _nameValid => _name.text.trim().length >= 2;

  void _onEmailChanged(String value) {
    _debounce?.cancel();
    setState(() {
      _failure = null;
      _campus = const _CampusIdle();
    });
    final email = value.trim();
    final at = email.indexOf('@');
    if (at < 1 || !email.substring(at).contains('.')) return;
    _debounce = Timer(
      const Duration(milliseconds: 500),
      () => _checkCampus(email),
    );
  }

  Future<void> _checkCampus(String email) async {
    setState(() => _campus = const _CampusChecking());
    try {
      final campus = await ref
          .read(authRepositoryProvider)
          .resolveCampus(email);
      if (mounted && _email.text.trim() == email) {
        setState(() => _campus = _CampusFound(campus));
      }
    } on ApiFailure catch (failure) {
      if (!mounted || _email.text.trim() != email) return;
      // Sin red no se bloquea el registro: el back vuelve a validar al enviar.
      setState(
        () => _campus = failure.code == 'auth.email_not_institutional'
            ? const _CampusRejected()
            : const _CampusIdle(),
      );
    }
  }

  void _warn(String message) => showMusubiSnack(
    ScaffoldMessenger.of(context),
    message,
    icon: MusubiIcons.circleAlert,
    tone: SnackTone.warn,
    bottomOffset: AuthLayout.actionsHeight,
  );

  Future<void> _submit() async {
    final attempt = Object();
    setState(() {
      _attempt = attempt;
      _failure = null;
      _emailMissing = _email.text.trim().isEmpty;
      _nameMissing = !_nameValid;
      _passwordWeak = !PasswordRules.isValid(_password.text);
    });
    // Mismo orden que la maqueta: correo, nombre, contrasena y aviso.
    if (_emailMissing || _campus is _CampusRejected) {
      _emailFocus.requestFocus();
      return;
    }
    if (_nameMissing) return;
    if (_passwordWeak) {
      _warn('Tu contraseña necesita 8 caracteres, letras y números');
      return;
    }
    if (!_consent) {
      setState(() => _consentShake = Object());
      _warn('Acepta los términos para continuar');
      return;
    }

    setState(() => _submitting = true);
    try {
      final registration = await ref
          .read(authRepositoryProvider)
          .register(
            email: _email.text,
            fullName: _name.text,
            password: _password.text,
            acceptTerms: _consent,
            acceptPrivacy: _consent,
          );
      if (!mounted) return;
      unawaited(context.push(AppRoutes.verification, extra: registration));
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _failure = failure;
        if (failure.code == 'auth.email_not_institutional') {
          _campus = const _CampusRejected();
        }
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _fieldError(String field, Set<String> codes) {
    final failure = _failure;
    if (failure == null) return null;
    if (codes.contains(failure.code)) return failure.message;
    return failure.fieldError(field);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final failure = _failure;
    final rejected = _campus is _CampusRejected;
    // Rechazado: borde rojo y la explicacion va en su caja (sin linea).
    final emailError = rejected
        ? ''
        : _emailMissing && _email.text.trim().isEmpty
        ? 'Escribe tu correo institucional.'
        : _fieldError('email', const {});
    final bannerCodes = {
      'auth.email_already_registered',
      'auth.consent_required',
    };
    final showBanner =
        failure != null &&
        (bannerCodes.contains(failure.code) ||
            failure.isNetwork ||
            failure.code == ApiFailure.serverError ||
            failure.code == 'rate_limit.exceeded');

    return AuthLayout(
      onBack: () => leaveAuth(context, ref),
      actions: [
        MusubiButton(
          label: 'Crear cuenta',
          loading: _submitting,
          loadingLabel: 'Creando tu cuenta…',
          dimmed: rejected,
          onPressed: _submit,
        ),
        AuthFooterLink(
          question: '¿Ya tienes cuenta?',
          label: 'Inicia sesión',
          onTap: () => context.go(AppRoutes.signIn),
        ),
      ],
      children: [
        const AuthHeading(
          title: 'Crea tu cuenta',
          subtitle: TextSpan(text: 'Usa el correo de tu universidad.'),
          leading: Eyebrow('Paso 1 de 2'),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: MusubiSizes.space4,
            children: [
              MusubiTextField(
                label: 'Correo institucional',
                fieldKey: const Key('signup-email'),
                controller: _email,
                focusNode: _emailFocus,
                hint: 'tu.nombre@uttt.edu.mx',
                prefixIcon: MusubiIcons.mail,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                onChanged: _onEmailChanged,
                errorText: emailError,
                shakeTrigger: _attempt,
                suffix: switch (_campus) {
                  _CampusFound() => MusubiIcon(
                    MusubiIcons.circleCheck,
                    size: 20,
                    color: c.success,
                  ),
                  _CampusRejected() => MusubiIcon(
                    MusubiIcons.circleAlert,
                    size: 20,
                    color: c.error,
                  ),
                  _ => null,
                },
                footer: _CampusHint(check: _campus, shakeTrigger: _attempt),
              ),
              MusubiTextField(
                label: 'Nombre completo',
                fieldKey: const Key('signup-name'),
                controller: _name,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                inputFormatters: [LengthLimitingTextInputFormatter(120)],
                errorText: _nameMissing && !_nameValid
                    ? 'Escribe tu nombre completo.'
                    : _fieldError('fullName', const {}),
                shakeTrigger: _attempt,
                suffix: _nameValid
                    ? MusubiIcon(
                        MusubiIcons.circleCheck,
                        size: 20,
                        color: c.success,
                      )
                    : null,
              ),
              MusubiTextField(
                label: 'Contraseña',
                fieldKey: const Key('signup-password'),
                controller: _password,
                obscure: true,
                autofillHints: const [AutofillHints.newPassword],
                errorText:
                    _passwordWeak && !PasswordRules.isValid(_password.text)
                    ? 'Usa al menos 8 caracteres, con letras y números.'
                    : _fieldError('password', const {'auth.weak_password'}),
                shakeTrigger: _attempt,
                // `Registro-error` no muestra las reglas: la atencion va al
                // correo.
                footer: rejected
                    ? null
                    : Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: PasswordRuleList(password: _password.text),
                      ),
              ),
              _ConsentCheckbox(
                value: _consent,
                shakeTrigger: _consentShake,
                onChanged: (value) => setState(() {
                  _consent = value;
                  _failure = null;
                }),
              ),
              if (showBanner) ...[
                InlineMessage(message: failure.message, shakeTrigger: _attempt),
                if (failure.code == 'auth.email_already_registered')
                  Align(
                    alignment: Alignment.centerLeft,
                    child: MusubiButton(
                      label: 'Iniciar sesión',
                      kind: MusubiButtonKind.link,
                      onPressed: () => context.go(AppRoutes.signIn),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Bajo el correo: campus detectado, correo que no es de la universidad o
/// la pista de que el campus sale de lo que va despues de la @.
class _CampusHint extends StatelessWidget {
  const new({required this.check, required this.shakeTrigger});

  final _CampusCheck check;
  final Object? shakeTrigger;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return switch (check) {
      _CampusFound(:final campus) => RiseIn(
        key: const Key('campus-found'),
        offset: -4,
        duration: const Duration(milliseconds: 350),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: c.successSoft,
            borderRadius: BorderRadius.circular(MusubiSizes.radiusField),
          ),
          child: Row(
            spacing: 10,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c.brand,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: MusubiIcon(
                    MusubiIcons.graduationCap,
                    size: 18,
                    strokeWidth: 2.1,
                    color: Color(0xFFFFFFFF),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 1,
                  children: [
                    Text(
                      'Campus detectado: ${campus.shortName}',
                      style: MusubiType.style(
                        13.5,
                        weight: FontWeight.w800,
                        line: 18,
                        color: c.successText,
                      ),
                    ),
                    Text(
                      campus.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MusubiType.style(
                        12.5,
                        weight: FontWeight.w600,
                        line: 17,
                        color: c.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      _CampusRejected() => Shake(
        key: const Key('campus-rejected'),
        trigger: shakeTrigger,
        child: RiseIn(
          offset: -4,
          duration: const Duration(milliseconds: 350),
          delay: const Duration(milliseconds: 100),
          child: Semantics(
            liveRegion: true,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: c.errorSoft,
                borderRadius: BorderRadius.circular(MusubiSizes.radiusThumb),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  MusubiIcon(
                    MusubiIcons.triangleAlert,
                    size: 18,
                    strokeWidth: 2.2,
                    color: c.error,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        Text(
                          'Este correo no es de tu universidad',
                          style: MusubiType.style(
                            13.5,
                            weight: FontWeight.w800,
                            line: 18,
                            color: c.error,
                          ),
                        ),
                        Text(
                          'Usa el correo que te dio tu universidad, por '
                          'ejemplo tu.nombre@uttt.edu.mx. Con él detectamos '
                          'tu campus.',
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
          ),
        ),
      ),
      _CampusIdle() || _CampusChecking() => FieldMessage(
        text: 'Tu campus se detecta con lo que va después de la @',
        icon: MusubiIcons.graduationCap,
        color: c.textSecondary,
      ),
    };
  }
}

/// "Acepto los Términos y condiciones y el Aviso de privacidad."
class _ConsentCheckbox extends StatefulWidget {
  const new({
    required this.value,
    required this.onChanged,
    required this.shakeTrigger,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final Object? shakeTrigger;

  @override
  State<_ConsentCheckbox> createState() => _ConsentCheckboxState();
}

class _ConsentCheckboxState extends State<_ConsentCheckbox> {
  late final _terms = TapGestureRecognizer()
    ..onTap = () => context.push(AppRoutes.terms);
  late final _privacy = TapGestureRecognizer()
    ..onTap = () => context.push(AppRoutes.privacy);

  @override
  void dispose() {
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final link = TextStyle(color: c.brandText, fontWeight: FontWeight.w700);
    return Transform.translate(
      offset: const Offset(-11, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          MusubiCheckbox(
            key: const Key('signup-consent'),
            value: widget.value,
            semanticLabel: 'Acepto los términos y el aviso de privacidad',
            shakeTrigger: widget.shakeTrigger,
            onChanged: widget.onChanged,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 11),
              child: Text.rich(
                TextSpan(
                  style: MusubiType.style(14, line: 21, color: c.textSecondary),
                  children: [
                    const TextSpan(text: 'Acepto los '),
                    TextSpan(
                      text: 'Términos y condiciones',
                      style: link,
                      recognizer: _terms,
                    ),
                    const TextSpan(text: ' y el '),
                    TextSpan(
                      text: 'Aviso de privacidad',
                      style: link,
                      recognizer: _privacy,
                    ),
                    const TextSpan(text: '.'),
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
