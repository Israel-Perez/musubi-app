import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_panel.dart';
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/core/widgets/musubi_text_field.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/auth/presentation/password_rules.dart';

/// "Cambiar contraseña" (maqueta `Ajustes`, `aj-password`). Al guardar, la API
/// cierra las demas sesiones y devuelve una nueva: se guarda sin volver a
/// pedir el login.
Future<void> showChangePasswordSheet(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final changed = await showMusubiPanel<bool>(
    context,
    builder: (_) => const ChangePasswordSheet(),
  );
  if (changed ?? false) {
    showMusubiSnack(
      messenger,
      'Actualizamos tu contraseña',
      icon: MusubiIcons.shieldCheck,
    );
  }
}

class ChangePasswordSheet extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<ChangePasswordSheet> createState() =>
      _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<ChangePasswordSheet> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _nextFocus = FocusNode();
  String? _currentError;
  String? _nextError;
  int _currentShake = 0;
  int _nextShake = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // La maqueta enfoca la nueva al abrir (la actual ya viene escrita).
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _nextFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _nextFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final next = _next.text;
    final nextError = !PasswordRules.hasMinLength(next)
        ? 'Necesita al menos 8 caracteres.'
        : !PasswordRules.hasLetterAndDigit(next)
        ? 'Usa letras y números.'
        : null;
    setState(() {
      _currentError = _current.text.isEmpty
          ? 'Escribe tu contraseña actual.'
          : null;
      _nextError = nextError;
      if (_currentError != null) _currentShake++;
      if (_nextError != null) _nextShake++;
    });
    if (_currentError != null || _nextError != null) {
      if (_nextError != null) _nextFocus.requestFocus();
      return;
    }

    setState(() => _saving = true);
    try {
      final tokens = await ref
          .read(accountRepositoryProvider)
          .changePassword(current: _current.text, next: next);
      await ref.read(sessionControllerProvider.notifier).signIn(tokens);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        if (failure.code == 'auth.weak_password') {
          _nextError = failure.message;
          _nextShake++;
        } else {
          _currentError = failure.message;
          _currentShake++;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return MusubiPanel(
      key: const Key('change-password-sheet'),
      title: 'Cambiar contraseña',
      actions: [
        MusubiButton(
          key: const Key('change-password-submit'),
          label: 'Guardar contraseña',
          loadingLabel: 'Guardando…',
          loading: _saving,
          height: MusubiSizes.buttonHeightSheet,
          onPressed: _save,
        ),
        MusubiButton(
          label: 'Cancelar',
          kind: MusubiButtonKind.quiet,
          height: 46,
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          MusubiTextField(
            label: 'Contraseña actual',
            controller: _current,
            obscure: true,
            enabled: !_saving,
            errorText: _currentError,
            shakeTrigger: _currentShake,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.next,
            fieldKey: const Key('change-password-current'),
            sheet: true,
          ),
          const SizedBox(height: 12),
          MusubiTextField(
            label: 'Nueva contraseña',
            controller: _next,
            focusNode: _nextFocus,
            hint: 'Mínimo 8 caracteres',
            obscure: true,
            enabled: !_saving,
            errorText: _nextError,
            shakeTrigger: _nextShake,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
            fieldKey: const Key('change-password-new'),
            sheet: true,
            footer: _nextError == null
                ? Text(
                    'Usa letras y números.',
                    style: MusubiType.style(
                      12.5,
                      weight: FontWeight.w600,
                      line: 22,
                      color: c.textSecondary,
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
