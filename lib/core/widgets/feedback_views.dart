import 'package:flutter/material.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/css_line_box.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_sheet.dart';
import 'package:musubi_app/core/widgets/shake.dart';

enum InlineMessageKind { error, warning, success }

/// Aviso en linea de la maqueta (`Iniciar-sesion-error`): caja de radio 14
/// con icono de 22, titulo de 14 (peso 800) y texto de 13.5. El error usa el
/// rojo oxido, distinto del rojo de marca, y entra deslizandose.
class InlineMessage extends StatelessWidget {
  const new({
    required this.message,
    super.key,
    this.kind = InlineMessageKind.error,
    this.title,
    this.shakeTrigger,
  });

  final String message;
  final String? title;
  final InlineMessageKind kind;

  /// Cambia para sacudir el aviso cuando el error se repite.
  final Object? shakeTrigger;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final (ink, background, border, icon) = switch (kind) {
      InlineMessageKind.error => (
        c.error,
        c.errorSoft,
        c.errorBorder,
        MusubiIcons.circleAlert,
      ),
      InlineMessageKind.warning => (
        c.warningText,
        c.warningSoft,
        null,
        MusubiIcons.triangleAlert,
      ),
      InlineMessageKind.success => (
        c.successText,
        c.successSoft,
        null,
        MusubiIcons.circleCheck,
      ),
    };

    return Semantics(
      liveRegion: true,
      child: Shake(
        trigger: shakeTrigger,
        child: RiseIn(
          offset: -6,
          duration: const Duration(milliseconds: 350),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(MusubiSizes.radiusField),
              border: border == null ? null : Border.all(color: border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                MusubiIcon(icon, size: 22, color: ink),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      if (title != null)
                        CssLineBox(
                          fontSize: 14,
                          child: Text(
                            title!,
                            style: MusubiType.style(
                              14,
                              weight: FontWeight.w800,
                              color: ink,
                            ),
                          ),
                        ),
                      Text(
                        message,
                        style: MusubiType.style(
                          13.5,
                          line: 19,
                          color: c.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Entrada de la maqueta (`__rise`): aparece y se desliza [offset] px en
/// vertical. Respeta "quitar animaciones".
class RiseIn extends StatelessWidget {
  const new({
    required this.child,
    super.key,
    this.offset = 14,
    this.duration = const Duration(milliseconds: 400),
    this.delay = Duration.zero,
  });

  final Widget child;
  final double offset;
  final Duration duration;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return child;
    final total = delay + duration;
    final start = delay.inMicroseconds / total.inMicroseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1, curve: Curves.ease),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, offset * (1 - t)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Flota (`__fly` de la maqueta): sube [distance] px y regresa cada
/// [period] con `ease-in-out`. Da [cycles] vueltas y se queda quieto: una
/// animacion sin fin no deja que la pantalla se asiente (ni gasta bateria
/// mientras se escribe). Respeta "quitar animaciones".
class FloatY extends StatefulWidget {
  const new({
    required this.child,
    super.key,
    this.distance = 3,
    this.period = const Duration(milliseconds: 2600),
    this.cycles = 3,
  });

  final Widget child;
  final double distance;
  final Duration period;
  final int cycles;

  @override
  State<FloatY> createState() => _FloatYState();
}

class _FloatYState extends State<FloatY> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: widget.period * widget.cycles,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.value = 1;
    } else if (_controller.isDismissed) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, child) {
      // 0 → -distance → 0 en cada vuelta, como los keyframes 0 %, 50 %, 100 %.
      final lap = (_controller.value * widget.cycles) % 1;
      final half = lap < 0.5 ? lap * 2 : (1 - lap) * 2;
      return Transform.translate(
        offset: Offset(0, -widget.distance * Curves.easeInOut.transform(half)),
        child: child,
      );
    },
    child: widget.child,
  );
}

/// Aparece creciendo desde [from] (`__pop` de la maqueta): la hoja "Crea tu
/// cuenta" usa 0.6 con la curva de las hojas; las fotos de `Vender-1`, 0.92
/// con `ease`. Respeta "quitar animaciones".
class PopIn extends StatelessWidget {
  const new({
    required this.child,
    super.key,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 400),
    this.from = 0.6,
    this.curve = musubiEaseOut,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double from;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return child;
    final total = delay + duration;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(
        delay.inMicroseconds / total.inMicroseconds,
        1,
        curve: curve,
      ),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.scale(scale: from + (1 - from) * t, child: child),
      ),
      child: child,
    );
  }
}

/// Cargando: el arco que gira con su texto (RNF-12: nunca una espera muda).
class LoadingView extends StatelessWidget {
  const new({super.key, this.message = 'Cargando…'});

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Center(
      child: Semantics(
        label: message,
        liveRegion: true,
        child: ExcludeSemantics(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: MusubiSizes.space3,
            children: [
              MusubiSpinner(size: 28, color: c.brandText),
              Text(
                message,
                style: MusubiType.style(
                  14,
                  weight: FontWeight.w600,
                  color: c.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Vacio o seccion en camino: circulo gris de 112 con su icono, titulo,
/// explicacion y una accion opcional (forma de `Inicio-error`).
class EmptyView extends StatelessWidget {
  const new({
    required this.title,
    required this.message,
    super.key,
    this.icon = MusubiIcons.info,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  final String title;
  final String message;
  final MusubiIconData icon;
  final String? actionLabel;
  final MusubiIconData? actionIcon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                color: c.surface,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: MusubiIcon(
                  icon,
                  size: 48,
                  strokeWidth: 1.5,
                  color: c.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: MusubiType.style(
                23,
                weight: FontWeight.w800,
                line: 29,
                em: -0.025,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: MusubiSizes.space2),
            Text(
              message,
              textAlign: TextAlign.center,
              style: MusubiType.body.copyWith(color: c.textSecondary),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: MusubiSizes.space6),
              MusubiButton(
                label: actionLabel!,
                icon: actionIcon,
                iconSize: 19,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error con reintento (sin red o fallo del servidor).
class ErrorView extends StatelessWidget {
  const new({required this.message, required this.onRetry, super.key});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => EmptyView(
    title: 'Algo salió mal',
    message: message,
    icon: MusubiIcons.wifiOff,
    actionLabel: 'Reintentar',
    actionIcon: MusubiIcons.refreshCw,
    onAction: onRetry,
  );
}
