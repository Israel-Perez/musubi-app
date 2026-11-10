import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/app_version.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/avatars.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/core/widgets/top_bar.dart';
import 'package:musubi_app/features/auth/presentation/sign_out_button.dart';
import 'package:musubi_app/features/profile/presentation/change_password_sheet.dart';
import 'package:musubi_app/features/profile/presentation/email_sheet.dart';
import 'package:musubi_app/features/profile/presentation/personal_data_sheet.dart';
import 'package:musubi_app/features/profile/presentation/profile_providers.dart';
import 'package:musubi_app/features/profile/presentation/profile_screen.dart';
import 'package:musubi_app/features/profile/presentation/settings_row.dart';
import 'package:musubi_app/features/reputation/domain/reputation_models.dart';
import 'package:musubi_app/features/reputation/presentation/report_sheet.dart';
import 'package:musubi_app/features/profile/presentation/theme_preference_providers.dart';
import 'package:musubi_app/features/profile/presentation/theme_preference_sheet.dart';

/// `Ajustes` (HU-04): la tarjeta de la cuenta abre "Datos personales";
/// "Correo institucional", "Cambiar contraseña", "Privacidad · Quién te ve",
/// "Reportar un problema" (HU-28), apariencia, legal, "Cerrar sesión" y la
/// version. Lo que aun no existe no se muestra: NOTE (HU-55) pagos,
/// NOTE (HU-54) avisos y NOTE (HU-39) "Centro de ayuda".
class SettingsScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.musubi;
    final session = sessionProfile(ref);
    final me = ref.watch(myProfileProvider).value;
    final themePreference = ref.watch(themePreferenceProvider);
    return Scaffold(
      body: Column(
        children: [
          MusubiTopBar(onBack: () => context.pop(), title: 'Ajustes'),
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom + 32,
              ),
              children: [
                Pressable(
                  key: const Key('settings-account'),
                  onTap: () => unawaited(showPersonalDataSheet(context)),
                  semanticLabel: 'Datos personales',
                  builder: (context, pressed) => Container(
                    margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: pressed ? c.surfacePressed : c.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      spacing: 14,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ProfileAvatar(
                              initials: me?.initials ?? session?.initials ?? '',
                              photoUrl: me?.photoUrl,
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
                                me?.fullName ??
                                    session?.fullName ??
                                    'Tu cuenta',
                                style: MusubiType.style(
                                  16,
                                  weight: FontWeight.w800,
                                  color: c.textPrimary,
                                ),
                              ),
                              Text(
                                me?.email ?? session?.email ?? '',
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
                        MusubiIcon(
                          MusubiIcons.chevronRight,
                          size: 18,
                          color: c.chevron,
                        ),
                      ],
                    ),
                  ),
                ),
                const _SectionLabel('Cuenta'),
                _Group(
                  children: [
                    SettingsRow(
                      key: const Key('settings-email'),
                      icon: MusubiIcons.mail,
                      title: 'Correo institucional',
                      value: 'Verificado',
                      valueColor: c.successText,
                      onTap: () => unawaited(showEmailSheet(context)),
                    ),
                  ],
                ),
                const _SectionLabel('Apariencia'),
                _Group(
                  children: [
                    SettingsRow(
                      key: const Key('settings-theme'),
                      icon: MusubiIcons.moon,
                      title: 'Tema',
                      value: themePreference.isLoading
                          ? 'Cargando…'
                          : themePreference.hasError
                          ? 'Reintentar'
                          : themePreference.value?.label ?? 'Como el sistema',
                      onTap: themePreference.hasError
                          ? () => ref.invalidate(themePreferenceProvider)
                          : () => unawaited(
                              showThemePreferenceSheet(context, ref),
                            ),
                    ),
                  ],
                ),
                const _SectionLabel('Privacidad y seguridad'),
                _Group(
                  children: [
                    SettingsRow(
                      key: const Key('settings-password'),
                      icon: MusubiIcons.lock,
                      title: 'Cambiar contraseña',
                      onTap: () => unawaited(showChangePasswordSheet(context)),
                    ),
                    SettingsRow(
                      key: const Key('settings-privacy'),
                      icon: MusubiIcons.shieldCheck,
                      title: 'Privacidad',
                      value: 'Quién te ve',
                      onTap: () =>
                          unawaited(context.push(AppRoutes.accountPrivacy)),
                    ),
                  ],
                ),
                const _SectionLabel('Ayuda'),
                _Group(
                  children: [
                    SettingsRow(
                      key: const Key('settings-report'),
                      icon: MusubiIcons.flag,
                      title: 'Reportar un problema',
                      onTap: () =>
                          openReportSheet(context, const GeneralReport()),
                    ),
                    SettingsRow(
                      icon: MusubiIcons.fileText,
                      title: 'Aviso de privacidad',
                      onTap: () => unawaited(context.push(AppRoutes.privacy)),
                    ),
                    SettingsRow(
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Text(
                    'Musubi $appVersion',
                    key: const Key('settings-version'),
                    textAlign: TextAlign.center,
                    style: MusubiType.style(
                      12,
                      weight: FontWeight.w600,
                      line: 17,
                      color: c.textSecondary,
                    ),
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
