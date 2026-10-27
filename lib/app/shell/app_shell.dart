import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/app/shell/musubi_bottom_bar.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/feedback_views.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/top_bar.dart';
import 'package:musubi_app/features/auth/presentation/account_gate.dart';
import 'package:musubi_app/features/listings/presentation/publish_sheet.dart';
import 'package:musubi_app/features/listings/presentation/sell_draft.dart';

/// Marco de las 4 pestanas (cada una conserva su pila de navegacion).
///
/// Visitante (HU-48): Mensajes, Perfil y Publicar no navegan; abren la hoja
/// "Crea tu cuenta" y, al terminar, se vuelve a la pantalla actual. Con
/// sesion, "Publicar" abre "¿Qué quieres publicar?" detras de la barra, que
/// cambia su boton por "Cerrar" (maqueta `Publicar`).
class AppShell extends ConsumerStatefulWidget {
  const new({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  /// Pestanas que piden cuenta, con su motivo (indice de la barra).
  static const Map<int, AccountGateMotive> _membersOnly = {
    2: AccountGateMotive.messages,
    3: AccountGateMotive.profile,
  };

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _publishOpen = false;

  void _setPublish({required bool open}) {
    if (_publishOpen != open) setState(() => _publishOpen = open);
  }

  void _gate(AccountGateMotive motive) {
    final here = GoRouter.of(context)
        .routerDelegate
        .currentConfiguration
        .uri
        .path;
    unawaited(showAccountGate(context, motive: motive, returnTo: here));
  }

  void _openFlow(String route) {
    _setPublish(open: false);
    if (route == AppRoutes.sell) ref.read(sellDraftProvider.notifier).start();
    unawaited(context.push(route));
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = ref.watch(sessionControllerProvider) is SignedIn;
    final shell = widget.navigationShell;
    final barHeight =
        MusubiSizes.navBarHeight + MediaQuery.viewPaddingOf(context).bottom;

    return PopScope(
      canPop: !_publishOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _setPublish(open: false);
      },
      child: Scaffold(
        // La pantalla sigue debajo de la franja transparente del boton
        // "Publicar", como en la maqueta.
        extendBody: true,
        body: Stack(
          children: [
            shell,
            Positioned.fill(
              child: PublishOverlay(
                open: _publishOpen && signedIn,
                bottomInset: barHeight,
                onClose: () => _setPublish(open: false),
                onSell: () => _openFlow(AppRoutes.sell),
                onNeed: () => _openFlow(AppRoutes.need),
              ),
            ),
          ],
        ),
        bottomNavigationBar: MusubiBottomBar(
          currentIndex: shell.currentIndex,
          publishOpen: _publishOpen && signedIn,
          onTabSelected: (index) {
            _setPublish(open: false);
            final motive = AppShell._membersOnly[index];
            if (!signedIn && motive != null) {
              _gate(motive);
              return;
            }
            shell.goBranch(
              index,
              // Tocar la pestana activa regresa a su raiz.
              initialLocation: index == shell.currentIndex,
            );
          },
          onPublish: () => signedIn
              ? _setPublish(open: !_publishOpen)
              : _gate(AccountGateMotive.publish),
        ),
      ),
    );
  }
}

/// Seccion que todavia no tiene su HU implementada: titulo de la maqueta y
/// un aviso de "en camino" con la forma de `Inicio-error`.
class UpcomingSection extends StatelessWidget {
  const new({
    required this.title,
    required this.message,
    required this.icon,
    super.key,
    this.canGoBack = false,
  });

  final String title;
  final String message;
  final MusubiIconData icon;

  /// Pantalla fuera de las pestanas (Publicar, Notificaciones): con flecha.
  final bool canGoBack;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        if (canGoBack)
          MusubiTopBar(title: title, onBack: () => context.pop())
        else
          TabHeader(title: title),
        Expanded(
          child: SafeArea(
            top: false,
            child: EmptyView(title: 'Muy pronto', message: message, icon: icon),
          ),
        ),
      ],
    ),
  );
}
