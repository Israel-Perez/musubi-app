import 'package:flutter/material.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/feedback_views.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_sheet.dart';
import 'package:musubi_app/core/widgets/pressable.dart';

/// Hoja "¿Qué quieres publicar?" (maqueta `Publicar`). Va detras de la barra
/// inferior, que mientras tanto muestra "Cerrar": entra subiendo 80 px en
/// 0.42 s sobre un velo que aparece en 0.3 s.
class PublishOverlay extends StatefulWidget {
  const new({
    required this.open,
    required this.onClose,
    required this.onSell,
    required this.onNeed,
    required this.bottomInset,
    super.key,
  });

  final bool open;
  final VoidCallback onClose;
  final VoidCallback onSell;
  final VoidCallback onNeed;

  /// Alto de la barra inferior que queda encima de la hoja.
  final double bottomInset;

  @override
  State<PublishOverlay> createState() => _PublishOverlayState();
}

class _PublishOverlayState extends State<PublishOverlay>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    reverseDuration: const Duration(milliseconds: 220),
    value: widget.open ? 1 : 0,
  );

  @override
  void didUpdateWidget(PublishOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.open == oldWidget.open) return;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _controller.value = widget.open ? 1 : 0;
    } else if (widget.open) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (_controller.isDismissed) return const SizedBox.shrink();
        // Velo: 0.3 s de los 0.42 s; hoja: la curva de las hojas.
        final fade = Curves.ease.transform(
          (_controller.value / (300 / 420)).clamp(0.0, 1.0),
        );
        final rise = musubiEaseOut.transform(_controller.value);
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                key: const Key('publish-scrim'),
                behavior: HitTestBehavior.opaque,
                onTap: widget.onClose,
                child: ColoredBox(
                  color: c.scrim.withValues(alpha: c.scrim.a * fade),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Opacity(
                opacity: 0.3 + 0.7 * rise,
                child: Transform.translate(
                  offset: Offset(0, 80 * (1 - rise)),
                  child: child,
                ),
              ),
            ),
          ],
        );
      },
      child: _PublishSheet(
        bottomInset: widget.bottomInset,
        onSell: widget.onSell,
        onNeed: widget.onNeed,
      ),
    );
  }
}

class _PublishSheet extends StatelessWidget {
  const new({
    required this.bottomInset,
    required this.onSell,
    required this.onNeed,
  });

  final double bottomInset;
  final VoidCallback onSell;
  final VoidCallback onNeed;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    Duration ms(int value) => Duration(milliseconds: value);
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      label: '¿Qué quieres publicar?',
      explicitChildNodes: true,
      child: Container(
        key: const Key('publish-sheet'),
        padding: EdgeInsets.fromLTRB(20, 8, 20, bottomInset + 26),
        decoration: BoxDecoration(
          color: c.elevated,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(MusubiSizes.radiusSheet),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: c.borderStrong,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      '¿Qué quieres publicar?',
                      style: MusubiType.style(
                        22,
                        weight: FontWeight.w800,
                        line: 28,
                        em: -0.02,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    'Elige cómo quieres usar Musubi esta vez.',
                    style: MusubiType.style(
                      14.5,
                      line: 21,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            RiseIn(
              offset: 12,
              delay: ms(120),
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: _Choice(
                  key: const Key('publish-sell'),
                  icon: MusubiIcons.tag,
                  title: 'Vender un producto',
                  message: 'Publica algo que ya tienes: fotos, precio y listo.',
                  onTap: onSell,
                ),
              ),
            ),
            RiseIn(
              offset: 12,
              delay: ms(200),
              child: _Choice(
                key: const Key('publish-need'),
                icon: MusubiIcons.megaphone,
                title: 'Publicar lo que necesito',
                message:
                    'Di qué buscas y cuánto quieres pagar. Quien lo tenga '
                    'te responde.',
                highlighted: true,
                onTap: onNeed,
              ),
            ),
            RiseIn(
              offset: 12,
              delay: ms(280),
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: _Difference(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opcion de la hoja: "Vender un producto" o, en rojo claro, "Publicar lo que
/// necesito" con "SOLO EN MUSUBI".
class _Choice extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    required this.message,
    required this.onTap,
    super.key,
    this.highlighted = false,
  });

  final MusubiIconData icon;
  final String title;
  final String message;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Pressable(
      onTap: onTap,
      semanticLabel: '$title. $message',
      builder: (context, pressed) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
        decoration: BoxDecoration(
          color: highlighted
              ? c.brandSoft
              : pressed
              ? c.surface
              : c.elevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: highlighted ? c.brandSoftBorder : c.border,
            width: 1.5,
          ),
        ),
        child: Row(
          spacing: 14,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: highlighted ? c.brand : c.surface,
                borderRadius: BorderRadius.circular(MusubiSizes.radiusButton),
              ),
              child: Center(
                child: MusubiIcon(
                  icon,
                  size: 26,
                  strokeWidth: 1.8,
                  color: highlighted ? const Color(0xFFFFFFFF) : c.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 3,
                children: [
                  Text(
                    title,
                    style: MusubiType.style(
                      17,
                      weight: FontWeight.w800,
                      color: c.textPrimary,
                    ),
                  ),
                  Text(
                    message,
                    style: MusubiType.style(
                      13.5,
                      line: 19,
                      color: highlighted ? c.textPrimary : c.textSecondary,
                    ),
                  ),
                  if (highlighted)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: c.elevated,
                        borderRadius: BorderRadius.circular(
                          MusubiSizes.radiusChip,
                        ),
                      ),
                      child: Text(
                        'SOLO EN MUSUBI',
                        style: MusubiType.style(
                          10.5,
                          weight: FontWeight.w800,
                          em: 0.05,
                          color: c.brandStrongText,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // `width: 32px` en la maqueta, pero se encoge (flex-shrink) para
            // dejarle 223 al texto: queda del ancho del icono.
            SizedBox(
              width: 20,
              child: Center(
                child: MusubiIcon(
                  MusubiIcons.chevronRight,
                  size: 20,
                  color: highlighted ? c.brandStrongText : c.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "¿Cuál es la diferencia?".
class _Difference extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final text = MusubiType.style(13, line: 18, color: c.textPrimary);
    final bold = MusubiType.style(
      13,
      weight: FontWeight.w800,
      line: 18,
      color: c.textPrimary,
    );
    Widget row(MusubiIconData icon, String lead, String rest) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: MusubiIcon(icon, size: 16, color: c.textPrimary),
        ),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: text,
              children: [
                TextSpan(text: lead, style: bold),
                TextSpan(text: ' $rest'),
              ],
            ),
          ),
        ),
      ],
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(MusubiSizes.radiusButton),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Text(
            '¿Cuál es la diferencia?',
            style: MusubiType.style(
              13,
              weight: FontWeight.w800,
              color: c.textPrimary,
            ),
          ),
          row(
            MusubiIcons.tagPlain,
            'Vender:',
            'tú publicas un producto y te encuentran.',
          ),
          row(
            MusubiIcons.megaphone,
            'Lo que necesito:',
            'tú dices qué buscas y te ofrecen.',
          ),
        ],
      ),
    );
  }
}
