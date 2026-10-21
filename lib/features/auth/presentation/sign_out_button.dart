import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';

/// "Cerrar sesion" con su confirmacion (maqueta `Ajustes`, HU-02, L-10).
class SignOutButton extends ConsumerWidget {
  const new({super.key});

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.logout),
        title: const Text('¿Cerrar sesión?'),
        content: const Text(
          'Tus publicaciones y mensajes se quedan guardados. Vuelve a entrar '
          'con tu correo institucional.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            key: const Key('signout-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final session = ref.read(sessionControllerProvider.notifier);
    // Primero a Inicio (no pide sesion): asi la guardia no manda a "Iniciar
    // sesion" al quedar como visitante.
    context.go(AppRoutes.home);
    await session.logOut();
    messenger.showSnackBar(
      const SnackBar(content: Text('Cerraste sesión. ¡Vuelve pronto!')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => MusubiButton(
    label: 'Cerrar sesión',
    kind: MusubiButtonKind.secondary,
    icon: Icons.logout,
    onPressed: () => _confirm(context, ref),
  );
}
