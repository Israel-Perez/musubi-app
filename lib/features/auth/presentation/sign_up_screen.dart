import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/feedback_views.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_text_field.dart';
import 'package:musubi_app/features/auth/domain/auth_models.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/auth/presentation/password_rules.dart';

/// "Crea tu cuenta" (maqueta `Registro` / `Registro-error`, HU-01 y HU-47).
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
  Timer? _debounce;
  _CampusCheck _campus = const _CampusIdle();
  bool _consent = false;
  bool _submitting = false;
  ApiFailure? _failure;

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
    _name.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_submitting &&
      _email.text.trim().isNotEmpty &&
      _name.text.trim().length >= 2 &&
      PasswordRules.isValid(_password.text) &&
      _consent &&
      _campus is! _CampusRejected;

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

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _failure = null;
    });
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
    final textTheme = Theme.of(context).textTheme;
    final c = context.musubi;
    final failure = _failure;
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

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        // Formulario: Column dentro de SingleChildScrollView (construye todos
        // los campos; un ListView descartaria los que salen de la vista).
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            MusubiSizes.gutter,
            0,
            MusubiSizes.gutter,
            MusubiSizes.space8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('PASO 1 DE 2', style: textTheme.labelSmall),
              const SizedBox(height: MusubiSizes.space2),
              Text('Crea tu cuenta', style: textTheme.headlineMedium),
              const SizedBox(height: MusubiSizes.space1),
              Text(
                'Usa el correo de tu universidad.',
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: MusubiSizes.space6),
              MusubiTextField(
                label: 'Correo institucional',
                fieldKey: const Key('signup-email'),
                controller: _email,
                hint: 'tu.nombre@uttt.edu.mx',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                onChanged: _onEmailChanged,
                errorText: _campus is _CampusRejected
                    ? 'Este correo no es de tu universidad'
                    : _fieldError('email', const {}),
                helper: _campus is _CampusRejected
                    ? null
                    : 'Tu campus se detecta con lo que va después de la @',
              ),
              const SizedBox(height: MusubiSizes.space2),
              _CampusHint(check: _campus),
              const SizedBox(height: MusubiSizes.space4),
              MusubiTextField(
                label: 'Nombre completo',
                fieldKey: const Key('signup-name'),
                controller: _name,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                maxLength: 120,
                errorText: _fieldError('fullName', const {}),
              ),
              const SizedBox(height: MusubiSizes.space2),
              MusubiTextField(
                label: 'Contraseña',
                fieldKey: const Key('signup-password'),
                controller: _password,
                obscure: true,
                autofillHints: const [AutofillHints.newPassword],
                errorText: _fieldError('password', const {
                  'auth.weak_password',
                }),
              ),
              const SizedBox(height: MusubiSizes.space2),
              _Rule(
                ok: PasswordRules.hasMinLength(_password.text),
                text: 'Al menos 8 caracteres',
              ),
              _Rule(
                ok: PasswordRules.hasLetterAndDigit(_password.text),
                text: 'Una letra y un número',
              ),
              const SizedBox(height: MusubiSizes.space4),
              _ConsentCheckbox(
                value: _consent,
                onChanged: (value) => setState(() {
                  _consent = value;
                  _failure = null;
                }),
              ),
              if (showBanner) ...[
                const SizedBox(height: MusubiSizes.space3),
                InlineMessage(message: failure.message),
                if (failure.code == 'auth.email_already_registered')
                  Align(
                    alignment: Alignment.centerLeft,
                    child: MusubiButton(
                      label: 'Iniciar sesión',
                      kind: MusubiButtonKind.text,
                      onPressed: () => context.go(AppRoutes.signIn),
                    ),
                  ),
              ],
              const SizedBox(height: MusubiSizes.space6),
              MusubiButton(
                label: 'Crear cuenta',
                loading: _submitting,
                onPressed: _canSubmit ? _submit : null,
              ),
              const SizedBox(height: MusubiSizes.space3),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('¿Ya tienes cuenta?', style: textTheme.bodyMedium),
                  MusubiButton(
                    label: 'Inicia sesión',
                    kind: MusubiButtonKind.text,
                    onPressed: () => context.go(AppRoutes.signIn),
                  ),
                ],
              ),
              Text(
                'Solo los estudiantes tienen correo institucional: así Musubi '
                'se queda solo para tu comunidad.',
                style: textTheme.bodyMedium?.copyWith(color: c.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CampusHint extends StatelessWidget {
  const new({required this.check});

  final _CampusCheck check;

  @override
  Widget build(BuildContext context) => switch (check) {
    _CampusFound(:final campus) => InlineMessage(
      key: const Key('campus-found'),
      kind: InlineMessageKind.success,
      title: 'Campus detectado: ${campus.shortName}',
      message: campus.name,
    ),
    _CampusRejected() => const InlineMessage(
      key: Key('campus-rejected'),
      title: 'Este correo no es de tu universidad',
      message:
          'Usa el correo que te dio tu universidad, por ejemplo '
          'tu.nombre@uttt.edu.mx. Con él detectamos tu campus.',
    ),
    _CampusChecking() => const LinearProgressIndicator(minHeight: 2),
    _CampusIdle() => const SizedBox.shrink(),
  };
}

class _Rule extends StatelessWidget {
  const new({required this.ok, required this.text});

  final bool ok;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final color = ok ? c.successText : c.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: color,
          ),
          const SizedBox(width: MusubiSizes.space2),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _ConsentCheckbox extends StatefulWidget {
  const new({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

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
    final textTheme = Theme.of(context).textTheme;
    final link = textTheme.bodyMedium?.copyWith(
      color: c.brandText,
      fontWeight: FontWeight.w800,
      decoration: TextDecoration.underline,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          key: const Key('signup-consent'),
          value: widget.value,
          activeColor: c.brand,
          onChanged: (value) => widget.onChanged(value ?? false),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text.rich(
              TextSpan(
                style: textTheme.bodyMedium?.copyWith(color: c.textPrimary),
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
    );
  }
}
