import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/app/shell/musubi_bottom_bar.dart';
import 'package:musubi_app/core/widgets/feedback_views.dart';

/// Marco de las 4 pestanas (cada una conserva su pila de navegacion).
class AppShell extends StatelessWidget {
  const new({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: navigationShell,
    bottomNavigationBar: MusubiBottomBar(
      currentIndex: navigationShell.currentIndex,
      onTabSelected: (index) => navigationShell.goBranch(
        index,
        // Tocar la pestana activa regresa a su raiz.
        initialLocation: index == navigationShell.currentIndex,
      ),
      onPublish: () => context.push(AppRoutes.publish),
    ),
  );
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
