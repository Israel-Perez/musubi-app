import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/core/session/session_tokens.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/avatars.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/core/widgets/top_bar.dart';
import 'package:musubi_app/features/auth/presentation/sign_out_button.dart';

SessionProfile? _profile(WidgetRef ref) =>
    switch (ref.watch(sessionControllerProvider)) {
      SignedIn(:final tokens) => tokens.profile,
      _ => null,
    };

/// Pestana Perfil (maqueta `Perfil`): la cuenta con su insignia y el engrane
/// de `Ajustes`. NOTE (HU-04): calificaciones, ventas, apartados y pedidos.
class ProfileScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.musubi;
    final profile = _profile(ref);
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              spacing: 14,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    InitialsAvatar(
                      initials: profile?.initials ?? '',
                      size: 72,
                      fontSize: 24,
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: c.background,
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
                        profile?.fullName ?? 'Tu cuenta',
                        style: MusubiType.style(
                          20,
                          weight: FontWeight.w800,
                          line: 25,
                          em: -0.02,
                          color: c.textPrimary,
                        ),
                      ),
                      if (profile != null)
                        Text(
                          '${profile.campus} · ${profile.email}',
                          maxLines: 1,
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
                          borderRadius: BorderRadius.circular(
                            MusubiSizes.radiusChip,
                          ),
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
                            Text(
                              'Verificada',
                              style: MusubiType.style(
                                11.5,
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
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            padding: const EdgeInsets.all(MusubiSizes.space4),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              spacing: MusubiSizes.space3,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: c.background,
                    borderRadius: BorderRadius.circular(
                      MusubiSizes.radiusField,
                    ),
                  ),
                  child: Center(
                    child: MusubiIcon(
                      MusubiIcons.clock,
                      size: 22,
                      strokeWidth: 1.9,
                      color: c.brandText,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(
                        'Muy pronto',
                        style: MusubiType.style(
                          14,
                          weight: FontWeight.w800,
                          color: c.textPrimary,
                        ),
                      ),
                      Text(
                        'Aquí verás tu reputación, tus ventas, tus compras y '
                        'tus apartados.',
                        style: MusubiType.style(
                          13,
                          line: 18,
                          color: c.textSecondary,
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

/// `Ajustes`: la cuenta, ayuda y legal, y "Cerrar sesión". NOTE (HU-54):
/// modo noche y preferencias de avisos.
class SettingsScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.musubi;
    final profile = _profile(ref);
    return Scaffold(
      body: Column(
        children: [
          MusubiTopBar(onBack: () => context.pop(), title: 'Ajustes'),
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom + 24,
              ),
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    spacing: 14,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          InitialsAvatar(
                            initials: profile?.initials ?? '',
                            size: 52,
                            fontSize: 17,
                          ),
                          const Positioned(
                            right: -3,
                            bottom: -3,
                            child: VerifiedBadge(size: 20),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 2,
                          children: [
                            Text(
                              profile?.fullName ?? 'Tu cuenta',
                              style: MusubiType.style(
                                16,
                                weight: FontWeight.w800,
                                color: c.textPrimary,
                              ),
                            ),
                            if (profile != null)
                              Text(
                                profile.email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: MusubiType.style(
                                  13,
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
                const _SectionLabel('Cuenta'),
                _Group(
                  children: [
                    _SettingsRow(
                      icon: MusubiIcons.mail,
                      title: 'Correo institucional',
                      value: 'Verificado',
                      valueColor: c.successText,
                    ),
                  ],
                ),
                const _SectionLabel('Ayuda'),
                _Group(
                  children: [
                    _SettingsRow(
                      icon: MusubiIcons.fileText,
                      title: 'Aviso de privacidad',
                      onTap: () => unawaited(context.push(AppRoutes.privacy)),
                    ),
                    _SettingsRow(
                      icon: MusubiIcons.shieldCheck,
                      title: 'Términos y condiciones',
                      onTap: () => unawaited(context.push(AppRoutes.terms)),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: SignOutButton(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "CUENTA": 12, peso 800, espaciado de 0.08 em y gris.
class _SectionLabel extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
    child: Text(
      text.toUpperCase(),
      style: MusubiType.style(
        12,
        weight: FontWeight.w800,
        line: 16,
        em: 0.08,
        color: context.musubi.textSecondary,
      ),
    ),
  );
}

/// Grupo de filas con borde de 1 y radio 18; filas separadas por una linea.
class _Group extends StatelessWidget {
  const new({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Container(height: 1, color: c.divider),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Fila de `Ajustes`: icono en su cuadro de 36, titulo, valor y flecha.
class _SettingsRow extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    this.value,
    this.valueColor,
    this.onTap,
  });

  final MusubiIconData icon;
  final String title;
  final String? value;
  final Color? valueColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    Widget row({bool pressed = false}) => Container(
      constraints: const BoxConstraints(minHeight: 60),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: pressed ? c.surface : null,
      child: Row(
        spacing: MusubiSizes.space3,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(
              child: MusubiIcon(
                icon,
                size: 19,
                strokeWidth: 1.9,
                color: c.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              style: MusubiType.style(
                15,
                weight: FontWeight.w700,
                line: 20,
                color: c.textPrimary,
              ),
            ),
          ),
          if (value != null)
            Text(
              value!,
              style: MusubiType.style(
                13.5,
                weight: FontWeight.w700,
                color: valueColor ?? c.textSecondary,
              ),
            ),
          if (onTap != null)
            MusubiIcon(
              MusubiIcons.chevronRight,
              size: 18,
              color: c.textSecondary,
            ),
        ],
      ),
    );
    return onTap == null
        ? Semantics(
            label: value == null ? title : '$title: $value',
            excludeSemantics: true,
            child: row(),
          )
        : Pressable(
            onTap: onTap,
            semanticLabel: title,
            builder: (context, pressed) => row(pressed: pressed),
          );
  }
}
