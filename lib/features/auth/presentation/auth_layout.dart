import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/return_path.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/top_bar.dart';

/// Esqueleto de las pantallas de cuenta de la maqueta (`Iniciar-sesion`,
/// `Registro`, `Verificacion`): flecha "Regresar", contenido que se desplaza
/// y acciones fijas abajo (a 24 del borde), que suben con el teclado.
class AuthLayout extends StatelessWidget {
  const new({
    required this.children,
    required this.actions,
    super.key,
    this.onBack,
    this.trailing,
    this.bottom = 24,
  });

  final List<Widget> children;

  /// Boton principal y lo que va debajo (separados 6).
  final List<Widget> actions;

  /// `null` sin flecha (`Verificacion-lista`).
  final VoidCallback? onBack;

  /// A la derecha de la barra ("PASO 2 DE 2").
  final Widget? trailing;

  /// Distancia de las acciones al borde inferior.
  final double bottom;

  /// Alto aproximado de las acciones fijas, para subir los avisos breves.
  static const double actionsHeight = 56.0 + 6 + 44 + 24;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        MusubiTopBar(onBack: onBack, trailing: trailing),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: MusubiSizes.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
        SafeArea(
          top: false,
          minimum: EdgeInsets.only(bottom: bottom),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: MusubiSizes.gutter),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 6,
              children: actions,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Titulo de 28 (o 26) con su texto de apoyo, en el margen de 20.
class AuthHeading extends StatelessWidget {
  const new({
    required this.title,
    super.key,
    this.subtitle,
    this.leading,
    this.size = 28,
    this.gap = 6,
    this.top = 8,
  });

  final String title;

  /// Texto de apoyo (puede llevar partes en negritas).
  final InlineSpan? subtitle;

  /// Lo que va arriba del titulo (anillos, "PASO 1 DE 2", icono).
  final Widget? leading;
  final double size;
  final double gap;
  final double top;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, top, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: gap,
        children: [
          ?leading,
          Semantics(
            header: true,
            child: Text(
              title,
              style: MusubiType.style(
                size,
                weight: FontWeight.w800,
                line: size == 28 ? 34 : 32,
                em: -0.025,
                color: c.textPrimary,
              ),
            ),
          ),
          if (subtitle != null)
            Text.rich(
              subtitle!,
              style: MusubiType.body.copyWith(color: c.textSecondary),
            ),
        ],
      ),
    );
  }
}

/// "¿Eres nuevo en Musubi? Crea tu cuenta": texto gris y enlace rojo en una
/// fila de 44.
class AuthFooterLink extends StatelessWidget {
  const new({
    required this.question,
    required this.label,
    required this.onTap,
    super.key,
  });

  final String question;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: MusubiSizes.minTouch,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 4,
      children: [
        Text(
          question,
          style: MusubiType.style(14, color: context.musubi.textSecondary),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: MusubiButton(
            label: label,
            kind: MusubiButtonKind.link,
            onPressed: onTap,
          ),
        ),
      ],
    ),
  );
}

/// Regreso de "Iniciar sesión" y "Crea tu cuenta": atras si hay pila; si se
/// llego con `go`, a la pantalla desde la que se abrio (`?desde=`).
void leaveAuth(BuildContext context, WidgetRef ref) {
  if (context.canPop()) {
    context.pop();
    return;
  }
  context.go(
    AppRoutes.safeReturn(
      GoRouterState.of(context).uri.queryParameters[AppRoutes.returnParam] ??
          ref.read(returnPathProvider),
    ),
  );
}
