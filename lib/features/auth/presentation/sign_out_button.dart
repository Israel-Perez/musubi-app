import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/musubi_dialog.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/core/widgets/pressable.dart';

/// "Cerrar sesion" de `Ajustes` (HU-02, L-10): boton con borde y texto rojo,
/// dialogo de confirmacion y el aviso "Cerraste sesión. ¡Vuelve pronto!".
class SignOutButton extends ConsumerWidget {
  const new({super.key});

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final confirmed = await showMusubiDialog(
      context,
      icon: MusubiIcons.logOut,
      title: '¿Cerrar sesión?',
      message:
          'Tus publicaciones y mensajes se quedan guardados. Vuelve a entrar '
          'con tu correo institucional.',
      confirmLabel: 'Cerrar sesión',
      danger: true,
      confirmKey: const Key('signout-confirm'),
    );
    if (!confirmed || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final session = ref.read(sessionControllerProvider.notifier);
    // Primero a Inicio (no pide sesion): asi la guardia no manda a "Iniciar
    // sesion" al quedar como visitante.
    context.go(AppRoutes.home);
    await session.logOut();
    showMusubiSnack(
      messenger,
      'Cerraste sesión. ¡Vuelve pronto!',
      icon: MusubiIcons.logOut,
      tone: SnackTone.info,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.musubi;
    return Pressable(
      onTap: () => _confirm(context, ref),
      semanticLabel: 'Cerrar sesión',
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
            MusubiIcon(MusubiIcons.logOut, size: 19, color: c.brandText),
            Text(
              'Cerrar sesión',
              style: MusubiType.style(
                15.5,
                weight: FontWeight.w800,
                color: c.brandText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
