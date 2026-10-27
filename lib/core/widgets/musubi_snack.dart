import 'package:flutter/material.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/pressable.dart';

/// Tono del aviso breve: el color del circulo del icono (`.snack-ico`).
enum SnackTone {
  /// Verde: algo salio bien.
  success,

  /// Gris: informacion ("Cerraste sesión").
  info,

  /// Rojo: falta algo para continuar.
  warn,
}

/// Aviso breve de la maqueta (`UI.snack`): tarjeta oscura (clara en modo
/// noche) a 14 de los lados y 12 arriba de la barra inferior o de
/// [bottomOffset] (las acciones fijas de la pantalla). Recibe el
/// [messenger] para poder avisar despues de navegar.
void showMusubiSnack(
  ScaffoldMessengerState messenger,
  String message, {
  MusubiIconData icon = MusubiIcons.check,
  SnackTone tone = SnackTone.success,
  String? actionLabel,
  VoidCallback? onAction,
  double bottomOffset = 0,
  Duration duration = const Duration(seconds: 3),
}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        margin: EdgeInsets.fromLTRB(14, 0, 14, 12 + bottomOffset),
        duration: duration,
        content: MusubiSnack(
          message: message,
          icon: icon,
          tone: tone,
          actionLabel: actionLabel,
          onAction: onAction == null
              ? null
              : () {
                  messenger.hideCurrentSnackBar();
                  onAction();
                },
        ),
      ),
    );
}

/// Tarjeta del aviso breve (ver [showMusubiSnack]).
class MusubiSnack extends StatelessWidget {
  const new({
    required this.message,
    super.key,
    this.icon = MusubiIcons.check,
    this.tone = SnackTone.success,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final MusubiIconData icon;
  final SnackTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final (circle, glyph) = switch (tone) {
      SnackTone.success => (c.success, const Color(0xFFFFFFFF)),
      SnackTone.info => (c.snackInfo, c.onSnackInfo),
      SnackTone.warn => (c.brand, const Color(0xFFFFFFFF)),
    };
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: c.snack,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4D000000),
            offset: Offset(0, 14),
            blurRadius: 34,
          ),
        ],
      ),
      child: Row(
        spacing: 10,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: circle, shape: BoxShape.circle),
            child: Center(
              child: MusubiIcon(icon, size: 18, strokeWidth: 2.4, color: glyph),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                message,
                style: MusubiType.style(
                  14.5,
                  weight: FontWeight.w600,
                  line: 20,
                  color: c.onSnack,
                ),
              ),
            ),
          ),
          if (actionLabel != null)
            Pressable(
              onTap: onAction,
              semanticLabel: actionLabel,
              builder: (context, _) => Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                child: Text(
                  actionLabel!,
                  style: MusubiType.style(
                    14.5,
                    weight: FontWeight.w800,
                    color: c.snackAction,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
