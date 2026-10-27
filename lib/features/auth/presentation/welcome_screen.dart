import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/return_path.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/avatars.dart';
import 'package:musubi_app/core/widgets/feedback_views.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/features/auth/domain/auth_models.dart';
import 'package:musubi_app/features/auth/presentation/auth_layout.dart';

/// "Correo verificado" (maqueta `Verificacion-lista`, HU-03).
class WelcomeScreen extends ConsumerWidget {
  const new({required this.user, super.key});

  final AuthUser? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.musubi;
    final user = this.user;
    Duration ms(int value) => Duration(milliseconds: value);
    Widget rise(int delay, Widget child) =>
        RiseIn(offset: 12, duration: ms(500), delay: ms(delay), child: child);

    return AuthLayout(
      bottom: 34,
      actions: [
        MusubiButton(
          label: 'Empezar a explorar',
          trailingIcon: MusubiIcons.arrowRight,
          iconSize: 20,
          // Vuelve a donde estaba al abrir "Crea tu cuenta" (HU-48).
          onPressed: () =>
              context.go(ref.read(returnPathProvider.notifier).take()),
        ),
      ],
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: Column(
            spacing: MusubiSizes.space3,
            children: [
              const _VerifiedSeal(),
              rise(
                500,
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: c.successSoft,
                    borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 6,
                    children: [
                      MusubiIcon(
                        MusubiIcons.check,
                        size: 15,
                        strokeWidth: 2.6,
                        color: c.successText,
                      ),
                      Text(
                        'Correo verificado',
                        style: MusubiType.style(
                          13,
                          weight: FontWeight.w800,
                          color: c.successText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              rise(
                600,
                Semantics(
                  header: true,
                  child: Text(
                    user == null
                        ? '¡Listo! Ya eres parte de Musubi'
                        : '¡Listo, ${user.firstName}! Ya eres parte de Musubi',
                    textAlign: TextAlign.center,
                    style: MusubiType.style(
                      26,
                      weight: FontWeight.w800,
                      line: 32,
                      em: -0.025,
                      color: c.textPrimary,
                    ),
                  ),
                ),
              ),
              rise(
                700,
                Text(
                  user == null
                      ? 'Compra, vende y pide en tu campus.'
                      : 'Ya eres parte de la ${user.campus.shortName}. '
                            'Compra, vende y pide.',
                  textAlign: TextAlign.center,
                  style: MusubiType.body.copyWith(color: c.textSecondary),
                ),
              ),
            ],
          ),
        ),
        if (user != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: rise(800, _UserCard(user: user)),
          ),
      ],
    );
  }
}

/// Tarjeta de la cuenta recien creada: iniciales, nombre verificado, correo y
/// "Campus UTTT".
class _UserCard extends StatelessWidget {
  const new({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border),
      ),
      child: Row(
        spacing: MusubiSizes.space3,
        children: [
          InitialsAvatar(initials: user.initials, size: 48, fontSize: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Row(
                  spacing: 6,
                  children: [
                    Flexible(
                      child: Text(
                        user.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MusubiType.style(
                          15.5,
                          weight: FontWeight.w800,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                    const VerifiedBadge(size: 17),
                  ],
                ),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MusubiType.style(
                    12.5,
                    weight: FontWeight.w600,
                    color: c.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  height: 26,
                  padding: const EdgeInsets.only(left: 3, right: 10),
                  decoration: BoxDecoration(
                    color: c.brandSoft,
                    borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 6,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: c.brand,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: MusubiIcon(
                            MusubiIcons.graduationCap,
                            size: 12,
                            strokeWidth: 2.4,
                            color: Color(0xFFFFFFFF),
                          ),
                        ),
                      ),
                      Text(
                        'Campus ${user.campus.shortName}',
                        style: MusubiType.style(
                          12,
                          weight: FontWeight.w800,
                          color: c.brandStrongText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Circulo rojo claro de 112 con ondas (`__wave`, tres veces) y la
/// insignia de 66 que entra como sello (`__stamp`).
class _VerifiedSeal extends StatefulWidget {
  const new();

  @override
  State<_VerifiedSeal> createState() => _VerifiedSealState();
}

class _VerifiedSealState extends State<_VerifiedSeal>
    with TickerProviderStateMixin {
  /// 0.8 s de espera y tres ondas de 2.4 s (la maqueta repite sin fin; aqui
  /// tres veces, sin un ticker eterno que gaste bateria).
  late final _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _delay + 3 * _period),
  );
  static const _delay = 800;
  static const _period = 2400;
  late final _stamp = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _stamp.value = 1;
      return;
    }
    _stamp.forward().ignore();
    _wave.forward().ignore();
  }

  @override
  void dispose() {
    _wave.dispose();
    _stamp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final disc = Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(color: c.brandSoft, shape: BoxShape.circle),
    );
    return SizedBox.square(
      dimension: 112,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _wave,
            builder: (context, child) {
              final elapsed = _wave.value * (_delay + 3 * _period) - _delay;
              if (elapsed < 0 || !_wave.isAnimating) {
                return const SizedBox.shrink();
              }
              final t = Curves.easeOut.transform((elapsed % _period) / _period);
              return Opacity(
                opacity: 0.7 * (1 - t),
                child: Transform.scale(scale: 0.8 + 0.7 * t, child: child),
              );
            },
            child: disc,
          ),
          disc,
          AnimatedBuilder(
            animation: _stamp,
            builder: (context, child) {
              // 0 → 60 %: de 0.4 y -20° a 1.08 y 4°; luego a 1 y 0°.
              final t = _stamp.value;
              final (scale, turn, opacity) = t < 0.6
                  ? (0.4 + 0.68 * (t / 0.6), -20 + 24 * (t / 0.6), t / 0.6)
                  : (
                      1.08 - 0.08 * ((t - 0.6) / 0.4),
                      4 - 4 * ((t - 0.6) / 0.4),
                      1.0,
                    );
              return Opacity(
                opacity: opacity,
                child: Transform.rotate(
                  angle: turn * math.pi / 180,
                  child: Transform.scale(scale: scale, child: child),
                ),
              );
            },
            child: const VerifiedBadge(size: 66, checkWidth: 2),
          ),
        ],
      ),
    );
  }
}
