import 'package:flutter/material.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_sheet.dart';

/// Dialogo de confirmacion de la maqueta (`.dlg`): icono de 58 en su cuadro,
/// titulo, texto y dos acciones apiladas. Devuelve `true` si se confirma.
Future<bool> showMusubiDialog(
  BuildContext context, {
  required MusubiIconData icon,
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancelar',
  bool danger = false,
  Key? confirmKey,
}) async {
  final c = context.musubi;
  final confirmed = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: cancelLabel,
    barrierColor: c.dialogScrim,
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, _, _) => MusubiDialog(
      icon: icon,
      title: title,
      message: message,
      danger: danger,
      actions: [
        MusubiButton(
          key: confirmKey,
          label: confirmLabel,
          height: MusubiSizes.buttonHeightSheet,
          onPressed: () => Navigator.of(context).pop(true),
        ),
        MusubiButton(
          label: cancelLabel,
          kind: MusubiButtonKind.quiet,
          height: 46,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    ),
    // `aPop`: aparece desde 0.86 con la curva de la maqueta.
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: musubiEaseOut);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.86, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
  return confirmed ?? false;
}

/// Tarjeta del dialogo (ver [showMusubiDialog]).
class MusubiDialog extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    required this.message,
    required this.actions,
    super.key,
    this.danger = false,
  });

  final MusubiIconData icon;
  final String title;
  final String message;
  final List<Widget> actions;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26),
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
            decoration: BoxDecoration(
              color: c.elevated,
              borderRadius: BorderRadius.circular(26),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x47000000),
                  offset: Offset(0, 24),
                  blurRadius: 60,
                ),
              ],
            ),
            child: Semantics(
              scopesRoute: true,
              namesRoute: true,
              explicitChildNodes: true,
              label: title,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: danger ? c.brandSoft : c.elevatedSurface,
                        borderRadius: BorderRadius.circular(19),
                      ),
                      child: Center(
                        child: MusubiIcon(
                          icon,
                          size: 26,
                          color: danger ? c.brandText : c.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: MusubiType.title2.copyWith(color: c.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: MusubiType.style(
                      14.5,
                      line: 21,
                      color: c.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 4,
                    children: actions,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
