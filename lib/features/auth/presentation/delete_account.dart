import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_dialog.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_sheet.dart';
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/core/widgets/musubi_text_field.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';

/// "Eliminar mi cuenta" de `Privacidad` (HU-46): boton con borde y texto rojo,
/// el dialogo de la maqueta y, como agregado de seguridad, la contrasena
/// actual. Al terminar vuelve a Inicio como visitante.
class DeleteAccountButton extends ConsumerWidget {
  const new({super.key});

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final confirmed = await showMusubiDialog(
      context,
      icon: MusubiIcons.x,
      title: '¿Eliminar tu cuenta?',
      message:
          'Se borran tu perfil, tus publicaciones y tus chats. No se puede '
          'deshacer.',
      confirmLabel: 'Eliminar cuenta',
      danger: true,
      confirmKey: const Key('delete-account-confirm'),
    );
    if (!confirmed || !context.mounted) return;

    final deleted = await showMusubiSheet<bool>(
      context,
      style: MusubiSheetStyle.screen,
      builder: (_) => const ConfirmPasswordSheet(),
    );
    if (deleted != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final session = ref.read(sessionControllerProvider.notifier);
    // Primero a Inicio (no pide sesion): asi la guardia no manda a "Iniciar
    // sesion" al quedar como visitante. La API ya borro las sesiones: solo se
    // limpia el dispositivo.
    context.go(AppRoutes.home);
    await session.signOut();
    showMusubiSnack(
      messenger,
      'Eliminamos tu cuenta y tus datos.',
      tone: SnackTone.info,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.musubi;
    return Pressable(
      key: const Key('delete-account'),
      onTap: () => _start(context, ref),
      semanticLabel: 'Eliminar mi cuenta',
      builder: (context, pressed) => Container(
        height: 52,
        decoration: BoxDecoration(
          color: pressed ? c.surface : c.background,
          borderRadius: BorderRadius.circular(MusubiSizes.radiusButton),
          border: Border.all(color: c.border, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8,
          children: [
            MusubiIcon(MusubiIcons.trash, size: 19, color: c.dangerText),
            Text(
              'Eliminar mi cuenta',
              style: MusubiType.style(
                15.5,
                weight: FontWeight.w800,
                color: c.dangerText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hoja "Confirma tu contraseña": se cierra con `true` cuando la API borro la
/// cuenta.
class ConfirmPasswordSheet extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<ConfirmPasswordSheet> createState() =>
      _ConfirmPasswordSheetState();
}

class _ConfirmPasswordSheetState extends ConsumerState<ConfirmPasswordSheet> {
  final _password = TextEditingController();
  String? _error;
  bool _deleting = false;
  int _shake = 0;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_password.text.isEmpty) {
      setState(() {
        _error = 'Escribe tu contraseña.';
        _shake++;
      });
      return;
    }
    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      await ref.read(accountRepositoryProvider).deleteAccount(_password.text);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _deleting = false;
        _error = failure.message;
        _shake++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Column(
      key: const Key('confirm-password-sheet'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 14),
        Semantics(
          header: true,
          child: Text(
            'Confirma tu contraseña',
            style: MusubiType.style(
              22,
              weight: FontWeight.w800,
              line: 28,
              em: -0.02,
              color: c.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Por seguridad, escribe tu contraseña para eliminar tu cuenta.',
          style: MusubiType.style(14.5, line: 21, color: c.textSecondary),
        ),
        const SizedBox(height: 18),
        MusubiTextField(
          label: 'Contraseña',
          controller: _password,
          obscure: true,
          errorText: _error,
          shakeTrigger: _shake,
          autofillHints: const [AutofillHints.password],
          textInputAction: TextInputAction.done,
          enabled: !_deleting,
          onSubmitted: (_) => _delete(),
          fieldKey: const Key('delete-account-password'),
        ),
        const SizedBox(height: 22),
        MusubiButton(
          key: const Key('delete-account-submit'),
          label: 'Eliminar mi cuenta',
          loading: _deleting,
          loadingLabel: 'Eliminando…',
          onPressed: _delete,
        ),
        const SizedBox(height: 4),
        MusubiButton(
          label: 'Cancelar',
          kind: MusubiButtonKind.quiet,
          onPressed: _deleting ? null : () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}
