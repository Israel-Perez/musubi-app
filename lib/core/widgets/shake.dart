import 'package:flutter/widgets.dart';

/// Pasos de una sacudida (px a lo ancho), su duracion y la espera inicial.
enum ShakePattern {
  /// Campo con error (`__shake` de `Iniciar-sesion-error`): 0.4 s tras 0.1 s.
  field(
    [0, -5, 5, -3, 3, 0],
    Duration(milliseconds: 400),
    Curves.ease,
    delay: Duration(milliseconds: 100),
  ),

  /// Aviso o grupo que se repite (`.app-shake`): 0.42 s.
  alert(
    [0, -2, 4, -7, 7, -7, 7, -7, 4, -2, 0],
    Duration(milliseconds: 420),
    Cubic(0.36, 0.07, 0.19, 0.97),
  );

  new(this.steps, this.duration, this.curve, {this.delay = Duration.zero});

  final List<double> steps;
  final Duration duration;
  final Curve curve;
  final Duration delay;
}

/// Sacude a [child] cada vez que cambia [trigger] (se compara por identidad:
/// el mismo error repetido vuelve a sacudir si es otro objeto). Respeta
/// "quitar animaciones" del sistema.
class Shake extends StatefulWidget {
  const new({
    required this.trigger,
    required this.child,
    super.key,
    this.pattern = ShakePattern.alert,
  });

  /// `null` no sacude.
  final Object? trigger;
  final Widget child;
  final ShakePattern pattern;

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this);
  late Animation<double> _offset = _build();

  /// La espera va dentro de la animacion (sin temporizadores sueltos).
  Animation<double> _build() {
    final pattern = widget.pattern;
    final steps = pattern.steps;
    _controller.duration = pattern.delay + pattern.duration;
    final step = pattern.duration.inMicroseconds / (steps.length - 1);
    return TweenSequence<double>([
      if (pattern.delay > Duration.zero)
        TweenSequenceItem(
          tween: ConstantTween(0),
          weight: pattern.delay.inMicroseconds.toDouble(),
        ),
      for (var i = 1; i < steps.length; i++)
        TweenSequenceItem(
          tween: Tween(
            begin: steps[i - 1],
            end: steps[i],
          ).chain(CurveTween(curve: pattern.curve)),
          weight: step,
        ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(Shake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pattern != widget.pattern) _offset = _build();
    final changed = !identical(widget.trigger, oldWidget.trigger);
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (widget.trigger != null && changed && !reduced) {
      _controller.forward(from: 0).ignore();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _offset,
    builder: (context, child) =>
        Transform.translate(offset: Offset(_offset.value, 0), child: child),
    child: widget.child,
  );
}
