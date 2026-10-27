import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:musubi_app/core/theme/app_theme.dart';

/// Brillo compartido de los esqueletos de carga (`.sk` de la maqueta): un
/// solo reloj de 1.4 s para que todos brillen al mismo tiempo. Con "quitar
/// animaciones" se quedan quietos.
class SkeletonShimmer extends StatefulWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  State<SkeletonShimmer> createState() => _SkeletonShimmerState();
}

class _SkeletonShimmerState extends State<SkeletonShimmer>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _ShimmerScope(
    animation: CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    child: widget.child,
  );
}

class _ShimmerScope extends InheritedNotifier<Animation<double>> {
  const new({required Animation<double> animation, required super.child})
    : super(notifier: animation);

  static Animation<double>? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ShimmerScope>()?.notifier;
}

/// Bloque gris (o rojizo con [brand], `.skr`) de un esqueleto de carga.
class SkeletonBox extends StatelessWidget {
  const new({
    super.key,
    this.width,
    this.height,
    this.radius = 8,
    this.brand = false,
  });

  final double? width;
  final double? height;
  final double radius;
  final bool brand;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final phase = _ShimmerScope.of(context)?.value;
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _SkeletonPainter(
          base: brand ? c.skeletonBrand : c.skeleton,
          shine: brand ? c.skeletonBrandShine : c.skeletonShine,
          radius: radius,
          phase: phase,
        ),
      ),
    );
  }
}

class _SkeletonPainter extends CustomPainter {
  const new({
    required this.base,
    required this.shine,
    required this.radius,
    required this.phase,
  });

  final Color base;
  final Color shine;
  final double radius;

  /// 0 → 1 en cada vuelta; `null` sin brillo.
  final double? phase;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final paint = Paint()..color = base;
    final t = phase;
    if (t != null) {
      // `background-size: 400%` que pasa de `100%` a `0%`: el brillo cruza
      // de izquierda a derecha.
      final start = -3 * size.width * (1 - t);
      paint.shader = ui.Gradient.linear(
        Offset(start, 0),
        Offset(start + 4 * size.width, 0),
        [base, base, shine, base, base],
        const [0, 0.25, 0.5, 0.75, 1],
      );
    }
    canvas.drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(_SkeletonPainter oldDelegate) =>
      oldDelegate.phase != phase ||
      oldDelegate.base != base ||
      oldDelegate.shine != shine ||
      oldDelegate.radius != radius;
}
