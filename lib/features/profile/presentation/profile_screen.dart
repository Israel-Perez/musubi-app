import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/core/session/session_tokens.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/avatars.dart';
import 'package:musubi_app/core/widgets/css_line_box.dart';
import 'package:musubi_app/core/widgets/feedback_views.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/core/widgets/skeleton.dart';
import 'package:musubi_app/core/widgets/top_bar.dart';
import 'package:musubi_app/features/listings/domain/listing_models.dart';
import 'package:musubi_app/features/listings/presentation/listings_providers.dart';
import 'package:musubi_app/features/profile/domain/profile_models.dart';
import 'package:musubi_app/features/profile/presentation/profile_providers.dart';

/// Quien tiene la sesion, para pintar el nombre mientras carga el perfil.
SessionProfile? sessionProfile(WidgetRef ref) =>
    switch (ref.watch(sessionControllerProvider)) {
      SignedIn(:final tokens) => tokens.profile,
      _ => null,
    };

/// Pestana Perfil (maqueta `Perfil`, HU-04): foto o iniciales, nombre,
/// "UTTT · carrera · periodo", "Verificada", estadisticas y mosaicos. El
/// engrane abre `Ajustes`. Lo que aun no existe no se muestra:
/// NOTE (HU-52) "Mis apartados", NOTE (HU-14) "Mis solicitudes",
/// NOTE (HU-53) "Favoritos" y NOTE (HU-25) "Mis pedidos".
class ProfileScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.musubi;
    final session = sessionProfile(ref);
    final profile = ref.watch(myProfileProvider);
    final me = profile.value;
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom + 24,
        ),
        children: [
          TabHeader(
            title: 'Perfil',
            trailing: Pressable(
              key: const Key('profile-settings'),
              onTap: () => unawaited(context.push(AppRoutes.settings)),
              semanticLabel: 'Ajustes',
              builder: (context, _) => SizedBox.square(
                dimension: MusubiSizes.minTouch,
                child: Center(
                  child: MusubiIcon(
                    MusubiIcons.settings,
                    size: 22,
                    strokeWidth: 1.8,
                    color: c.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          _Identity(
            name: me?.fullName ?? session?.fullName ?? 'Tu cuenta',
            initials: me?.initials ?? session?.initials ?? '',
            photoUrl: me?.photoUrl,
            subtitle: me?.subtitle ?? session?.campus,
          ),
          ...switch (profile) {
            AsyncData(:final value) => [
              _StatsRow(stats: value.stats),
              const _Tiles(),
            ],
            AsyncError(:final error) when me == null => [
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: ErrorView(
                  message: error is ApiFailure
                      ? error.message
                      : 'No pudimos cargar tu perfil.',
                  onRetry: () => ref.invalidate(myProfileProvider),
                ),
              ),
            ],
            _ => [const _StatsSkeleton()],
          },
        ],
      ),
    );
  }
}

/// Foto, nombre, linea del campus y "Verificada".
class _Identity extends StatelessWidget {
  const new({
    required this.name,
    required this.initials,
    required this.photoUrl,
    required this.subtitle,
  });

  final String name;
  final String initials;
  final String? photoUrl;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        spacing: 14,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ProfileAvatar(
                key: const Key('profile-avatar'),
                initials: initials,
                photoUrl: photoUrl,
                size: 72,
                fontSize: 24,
              ),
              Positioned(
                right: -2,
                bottom: -2,
                // El anillo es el `fill="#FFFFFF"` del SVG: blanco tambien
                // en modo noche.
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFFFFF),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(child: VerifiedBadge(size: 23)),
                ),
              ),
            ],
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 3,
              children: [
                Text(
                  name,
                  style: MusubiType.style(
                    20,
                    weight: FontWeight.w800,
                    line: 25,
                    em: -0.02,
                    color: c.textPrimary,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    key: const Key('profile-subtitle'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: MusubiType.style(
                      13,
                      weight: FontWeight.w600,
                      color: c.textSecondary,
                    ),
                  ),
                Container(
                  margin: const EdgeInsets.only(top: 3),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: c.brandSoft,
                    borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 5,
                    children: [
                      MusubiIcon(
                        MusubiIcons.shieldCheck,
                        size: 13,
                        strokeWidth: 2.2,
                        color: c.brandStrongText,
                      ),
                      CssLineBox(
                        fontSize: 11.5,
                        child: Text(
                          'Verificada',
                          style: MusubiType.style(
                            11.5,
                            weight: FontWeight.w800,
                            color: c.brandStrongText,
                          ),
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

/// Calificacion, ventas y compras: tres columnas con borde de 1 y radio 18.
class _StatsRow extends StatelessWidget {
  const new({required this.stats});

  final ProfileStats stats;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final rating = stats.ratingAvg;
    final ratings = switch (stats.ratingCount) {
      0 => 'Sin calificaciones',
      1 => '1 calificación',
      final n => '$n calificaciones',
    };
    Widget cell(Widget value, String label, {bool divider = true}) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          border: divider ? Border(right: BorderSide(color: c.border)) : null,
        ),
        child: Column(
          spacing: 2,
          children: [
            value,
            // Numero y etiqueta con `line-height: normal`, como en Chrome.
            CssLineBox(
              fontSize: 11.5,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: MusubiType.style(
                  11.5,
                  weight: FontWeight.w700,
                  color: c.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    Widget number(String text) => CssLineBox(
      fontSize: 20,
      child: Text(
        text,
        style: MusubiType.style(
          20,
          weight: FontWeight.w800,
          color: c.textPrimary,
        ),
      ),
    );
    return Container(
      key: const Key('profile-stats'),
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      decoration: BoxDecoration(
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            cell(
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 4,
                children: [
                  number(rating == null ? '—' : rating.toStringAsFixed(1)),
                  if (rating != null)
                    const MusubiIcon(
                      MusubiIcons.star,
                      size: 16,
                      color: Color(0xFFE8A317),
                    ),
                ],
              ),
              ratings,
            ),
            cell(number('${stats.sales}'), 'Ventas'),
            cell(number('${stats.purchases}'), 'Compras', divider: false),
          ],
        ),
      ),
    );
  }
}

/// "Mis publicaciones" y "Privacidad" (`a.tile`).
class _Tiles extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref
        .watch(myListingsProvider)
        .value
        ?.where((l) => l.status == ListingStatus.active)
        .length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      // La fila de la cuadricula estira los dos mosaicos a la misma altura.
      child: IntrinsicHeight(
        child: Row(
          spacing: 10,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _Tile(
                key: const Key('tile-my-products'),
                icon: MusubiIcons.tag,
                title: 'Mis publicaciones',
                subtitle: switch (active) {
                  null => ' ',
                  1 => '1 activa',
                  final n => '$n activas',
                },
                onTap: () => unawaited(context.push(AppRoutes.myProducts)),
              ),
            ),
            Expanded(
              child: _Tile(
                key: const Key('tile-privacy'),
                icon: MusubiIcons.shieldCheck,
                title: 'Privacidad',
                subtitle: 'Tus datos',
                onTap: () => unawaited(context.push(AppRoutes.accountPrivacy)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final MusubiIconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Pressable(
      onTap: onTap,
      semanticLabel: '$title, $subtitle',
      builder: (context, pressed) => Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: pressed ? c.surfacePressed : c.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          spacing: 10,
          children: [
            MusubiIcon(icon, size: 22, strokeWidth: 1.9, color: c.textPrimary),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: MusubiType.style(
                      14,
                      weight: FontWeight.w800,
                      color: c.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: MusubiType.style(
                      12,
                      weight: FontWeight.w600,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Esqueleto de las estadisticas y los mosaicos mientras carga.
class _StatsSkeleton extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => const SkeletonShimmer(
    child: Padding(
      key: Key('profile-loading'),
      padding: EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        spacing: 12,
        children: [
          SkeletonBox(height: 70, radius: 18),
          Row(
            spacing: 10,
            children: [
              Expanded(child: SkeletonBox(height: 64, radius: 16)),
              Expanded(child: SkeletonBox(height: 64, radius: 16)),
            ],
          ),
        ],
      ),
    ),
  );
}
