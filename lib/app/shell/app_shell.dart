import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/app/shell/musubi_bottom_bar.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/core/widgets/feedback_views.dart';
import 'package:musubi_app/features/auth/presentation/account_gate.dart';

/// Marco de las 4 pestanas (cada una conserva su pila de navegacion).
///
/// Visitante (HU-48): Mensajes, Perfil y Publicar no navegan; abren la hoja
/// "Crea tu cuenta" y, al terminar, se vuelve a la pantalla actual.
class AppShell extends ConsumerWidget {
  const new({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  /// Pestanas que piden cuenta, con su motivo (indice de la barra).
  static const Map<int, AccountGateMotive> _membersOnly = {
    2: AccountGateMotive.messages,
    3: AccountGateMotive.profile,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(sessionControllerProvider) is SignedIn;

    void gate(AccountGateMotive motive) {
      final here = GoRouter.of(context)
          .routerDelegate
          .currentConfiguration
          .uri
          .path;
      unawaited(showAccountGate(context, motive: motive, returnTo: here));
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: MusubiBottomBar(
        currentIndex: navigationShell.currentIndex,
        onTabSelected: (index) {
          final motive = _membersOnly[index];
          if (!signedIn && motive != null) {
            gate(motive);
            return;
          }
          navigationShell.goBranch(
            index,
            // Tocar la pestana activa regresa a su raiz.
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        onPublish: () => signedIn
            ? unawaited(context.push(AppRoutes.publish))
            : gate(AccountGateMotive.publish),
      ),
    );
  }
}

/// Seccion que todavia no tiene su HU implementada.
class UpcomingSection extends StatelessWidget {
  const new({
    required this.title,
    required this.message,
    required this.icon,
    super.key,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: EmptyView(title: title, message: message, icon: icon),
  );
}
