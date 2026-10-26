import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/musubi_logo.dart';

/// En pruebas se apaga para no esperar la animacion en cada pantalla.
final brandSplashEnabledProvider = Provider<bool>((ref) => true);

/// Duracion total del splash (SCRUM-81): ~1.5 s, con la salida incluida.
const brandSplashDuration = Duration(milliseconds: 1500);

/// Con "reducir animaciones": solo el logo quieto y un fundido corto.
const brandSplashReducedDuration = Duration(milliseconds: 600);

/// Splash animado sobre la app (SCRUM-81). Sigue al splash nativo (mismo fondo
/// y los anillos en el mismo lugar): los anillos se acercan y se anudan, sale
/// "Musubi" y todo se desvanece hacia Inicio. La app ya se construye debajo,
/// asi que el splash no retrasa la carga; solo bloquea los toques mientras
/// se ve.
class BrandSplash extends ConsumerStatefulWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<BrandSplash> createState() => _BrandSplashState();
}

class _BrandSplashState extends ConsumerState<BrandSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: brandSplashDuration,
  );
  bool _started = false;
  bool _done = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!ref.read(brandSplashEnabledProvider)) {
      _done = true;
      return;
    }
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _controller.duration = reduced
        ? brandSplashReducedDuration
        : brandSplashDuration;
    unawaited(
      _controller.forward().whenComplete(() {
        if (mounted) setState(() => _done = true);
      }),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.child;
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        AbsorbPointer(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) =>
                _SplashFrame(progress: _controller.value, reduced: reduced),
          ),
        ),
      ],
    );
  }
}

class _SplashFrame extends StatelessWidget {
  const new({required this.progress, required this.reduced});

  final double progress;
  final bool reduced;

  /// Fraccion del avance dentro de [begin, end], con una curva.
  static double _segment(
    double t,
    double begin,
    double end, [
    Curve curve = Curves.easeOutCubic,
  ]) => curve.transform(((t - begin) / (end - begin)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    // Salida comun: el ultimo 20 % se desvanece hacia la app.
    final exit = _segment(progress, 0.8, 1, Curves.easeIn);

    final double separation;
    final bool interlaced;
    final double wordmark;
    if (reduced) {
      separation = 0;
      interlaced = true;
      wordmark = 1;
    } else {
      // 0-45 %: los anillos llegan desde los lados (+18 -> 0) y se anudan.
      final join = _segment(progress, 0, 0.45, Curves.easeInOutCubic);
      separation = 18 * (1 - join);
      interlaced = join >= 0.7;
      // 30-65 %: "Musubi" aparece y sube un poco.
      wordmark = _segment(progress, 0.3, 0.65);
    }

    return Opacity(
      opacity: 1 - exit,
      // Material: el splash vive sobre el Navigator, sin Scaffold que de estilo
      // de texto por defecto.
      child: Material(
        key: const Key('brand-splash'),
        color: c.background,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MusubiRings(
                height: 70,
                separation: separation,
                interlaced: interlaced,
              ),
              const SizedBox(height: MusubiSizes.space4),
              Opacity(
                opacity: wordmark,
                child: Transform.translate(
                  offset: Offset(0, 12 * (1 - wordmark)),
                  child: Text(
                    'Musubi',
                    style: MusubiType.title1.copyWith(
                      fontSize: 34,
                      letterSpacing: -1,
                      color: c.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
