import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';

/// "Revisa tu correo institucional" (maqueta `Verificacion`, HU-03).
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
  bool _resending = false;
  ApiFailure? _failure;
  String? _notice;

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

  Future<void> _verify(Registration registration) async {
    setState(() {
      _verifying = true;
      _failure = null;
      _notice = null;
    });
    final session = ref.read(sessionControllerProvider.notifier);
    try {
      final signedIn = await ref
          .read(authRepositoryProvider)
          .confirmCode(email: registration.email, code: _code.text);
      if (!mounted) return;
      // Primero se navega a la bienvenida (no es pantalla de visitante) y
      // despues se guarda la sesion, para que la guardia no redirija antes.
      context.go(AppRoutes.welcome, extra: signedIn.user);
      await session.signIn(signedIn.tokens);
    } on ApiFailure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend(Registration registration) async {
    setState(() {
      _resending = true;
      _failure = null;
      _notice = null;
    });
    try {
      final next = await ref
          .read(authRepositoryProvider)
          .resendCode(registration.email);
      if (!mounted) return;
      setState(() {
        _resendAt = next;
        _notice = 'Te enviamos un código nuevo.';
        _code.clear();
      });
      _tick();
    } on ApiFailure catch (failure) {
      if (mounted) setState(() => _failure = failure);
    } finally {
      if (mounted) setState(() => _resending = false);
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
    if (registration == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyView(
          title: 'Primero crea tu cuenta',
          message: 'Escribe tu correo institucional para recibir el código.',
          icon: Icons.mark_email_unread_outlined,
          actionLabel: 'Crear cuenta',
          onAction: () => context.go(AppRoutes.signUp),
        ),
      );
    }

    final textTheme = Theme.of(context).textTheme;
    final c = context.musubi;
    final failure = _failure;
    final codeError = failure != null && failure.code == 'auth.invalid_code'
        ? failure.message
        : failure?.fieldError('code');

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
              Text('PASO 2 DE 2', style: textTheme.labelSmall),
              const SizedBox(height: MusubiSizes.space2),
              Text(
                'Revisa tu correo institucional',
                style: textTheme.headlineMedium,
              ),
              const SizedBox(height: MusubiSizes.space2),
              Text(
                'Te enviamos un código de 6 dígitos a',
                style: textTheme.bodyLarge,
              ),
              Text(
                registration.email,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: MusubiSizes.space6),
              MusubiTextField(
                label: 'Código de verificación',
                fieldKey: const Key('verification-code'),
                controller: _code,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
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
                      key: const Key('resend-countdown'),
                      style: textTheme.bodyMedium,
                    )
                  else
                    MusubiButton(
                      label: 'Reenviar código',
                      kind: MusubiButtonKind.text,
                      loading: _resending,
                      onPressed: () => _resend(registration),
                    ),
                  const Spacer(),
                  MusubiButton(
                    label: 'Cambiar correo',
                    kind: MusubiButtonKind.text,
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go(AppRoutes.signUp),
                  ),
                ],
              ),
              if (_notice != null)
                InlineMessage(
                  kind: InlineMessageKind.success,
                  message: _notice!,
                ),
              if (failure != null && codeError == null) ...[
                const SizedBox(height: MusubiSizes.space2),
                InlineMessage(message: failure.message),
              ],
              const SizedBox(height: MusubiSizes.space4),
              Text(
                '¿No lo ves? Revisa tu carpeta de spam o correo no deseado.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: MusubiSizes.space4),
              Container(
                padding: const EdgeInsets.all(MusubiSizes.space4),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(MusubiSizes.radiusThumb),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿Por qué tu correo de la universidad?',
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: MusubiSizes.space1),
                    Text(
                      'Solo los estudiantes tienen uno. Así Musubi se queda '
                      'solo para tu comunidad.',
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: MusubiSizes.space6),
              MusubiButton(
                label: 'Verificar correo',
                loading: _verifying,
                onPressed: _code.text.length == 6 && !_verifying
                    ? () => _verify(registration)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
