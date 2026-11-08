import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_controls.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/core/widgets/skeleton.dart';
import 'package:musubi_app/core/widgets/top_bar.dart';
import 'package:musubi_app/features/auth/presentation/delete_account.dart';
import 'package:musubi_app/features/profile/domain/profile_models.dart';
import 'package:musubi_app/features/profile/presentation/profile_providers.dart';
import 'package:musubi_app/features/profile/presentation/settings_row.dart';
import 'package:musubi_app/features/reputation/presentation/blocked_users_sheet.dart';
import 'package:musubi_app/features/reputation/presentation/reputation_providers.dart';

/// `Privacidad` (maqueta; HU-04 y HU-46): el resumen rojo, "Quién te ve",
/// "Tus datos" ("Usuarios bloqueados", HU-57) y "Eliminar mi cuenta".
/// "Descargar mis datos" no tiene HU todavia.
class PrivacyScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Scaffold(
      body: Column(
        children: [
          MusubiTopBar(
            onBack: () => context.pop(),
            title: 'Privacidad',
            titleAtStart: true,
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom + 24,
              ),
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: c.brand,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    spacing: 14,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: c.background,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Center(
                          child: MusubiIcon(
                            MusubiIcons.shieldCheck,
                            size: 26,
                            color: c.brand,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 2,
                          children: [
                            Text(
                              'Tu perfil solo lo ve tu campus',
                              style: MusubiType.style(
                                17,
                                weight: FontWeight.w800,
                                line: 22,
                                em: -0.01,
                                color: c.onBrand,
                              ),
                            ),
                            Text(
                              'No vendemos tus datos.',
                              style: MusubiType.style(
                                13,
                                weight: FontWeight.w600,
                                line: 18,
                                color: c.onBrand,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const _SectionLabel('Quién te ve'),
                const _WhoSeesYou(),
                const _SectionLabel('Tus datos'),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.border),
                  ),
                  child: Column(
                    children: [
                      const _BlockedUsersRow(),
                      Container(height: 1, color: c.divider),
                      SettingsRow(
                        icon: MusubiIcons.fileText,
                        title: 'Aviso de privacidad',
                        onTap: () => unawaited(context.push(AppRoutes.privacy)),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: DeleteAccountButton(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Usuarios bloqueados" (HU-57): cuantos ("Ninguno" sin bloqueos) y abre la
/// hoja para desbloquear.
class _BlockedUsersRow extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(blockedUsersProvider).value?.length;
    return SettingsRow(
      key: const Key('privacy-blocked'),
      icon: MusubiIcons.ban,
      title: 'Usuarios bloqueados',
      value: switch (count) {
        null => null,
        0 => 'Ninguno',
        final n => '$n',
      },
      onTap: () => unawaited(showBlockedUsersSheet(context)),
    );
  }
}

/// "QUIÉN TE VE", "TUS DATOS": 13/18, peso 800, espaciado de 0.06 em y gris.
class _SectionLabel extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 6),
    child: Text(
      text.toUpperCase(),
      style: MusubiType.style(
        13,
        weight: FontWeight.w800,
        line: 18,
        em: 0.06,
        color: context.musubi.textSecondary,
      ),
    ),
  );
}

/// "Quién te ve" (HU-04): carrera, ventas y en linea. Cada interruptor se
/// guarda al tocarlo con el aviso de la maqueta; si la API falla regresa a
/// su estado anterior y lo explica. La API aplica la visibilidad en el
/// perfil publico (OWASP API3). NOTE (HU-21): "en linea" lo usa el chat.
class _WhoSeesYou extends ConsumerWidget {
  const new();

  static const _texts = {
    'career': ('Tu carrera se ve en tu perfil', 'Ocultamos tu carrera'),
    'sales': ('Tus ventas se ven en tu perfil', 'Ocultamos tus ventas'),
    'online': (
      'Ahora se ve cuando estás en línea',
      'Ya no se ve si estás en línea',
    ),
  };

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref, {
    required String key,
    required ProfileVisibility next,
    required bool on,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(myProfileProvider.notifier).setVisibility(next);
      final (shown, hidden) = _texts[key]!;
      showMusubiSnack(
        messenger,
        on ? shown : hidden,
        icon: on ? MusubiIcons.check : MusubiIcons.bellOff,
        tone: SnackTone.info,
        duration: const Duration(milliseconds: 1800),
      );
    } on ApiFailure catch (failure) {
      showMusubiSnack(
        messenger,
        'No pudimos guardar el cambio. ${failure.message}',
        icon: MusubiIcons.circleAlert,
        tone: SnackTone.warn,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.musubi;
    final profile = ref.watch(myProfileProvider);
    final visibility = profile.value?.visibility;
    Widget row({
      required String key,
      required MusubiIconData icon,
      required String title,
      required bool value,
      required ProfileVisibility Function({required bool on}) next,
    }) => Container(
      constraints: const BoxConstraints(minHeight: 60),
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      child: Row(
        spacing: 12,
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
                size: 20,
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
          MusubiSwitch(
            key: Key('visibility-$key'),
            value: value,
            semanticLabel: title,
            knobColor: c.background,
            onChanged: (on) => _toggle(
              context,
              ref,
              key: key,
              next: next(on: on),
              on: on,
            ),
          ),
        ],
      ),
    );
    final Widget body;
    if (visibility != null) {
      body = Column(
        children: [
          row(
            key: 'career',
            icon: MusubiIcons.graduationCap,
            title: 'Mostrar mi carrera',
            value: visibility.career,
            next: ({required on}) => visibility.copyWith(career: on),
          ),
          Container(height: 1, color: c.divider),
          row(
            key: 'sales',
            icon: MusubiIcons.shoppingBag,
            title: 'Mostrar mis ventas',
            value: visibility.sales,
            next: ({required on}) => visibility.copyWith(sales: on),
          ),
          Container(height: 1, color: c.divider),
          row(
            key: 'online',
            icon: MusubiIcons.clock,
            title: 'Mostrar si estoy en línea',
            value: visibility.online,
            next: ({required on}) => visibility.copyWith(online: on),
          ),
        ],
      );
    } else if (profile.hasError) {
      body = Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            Text(
              'No pudimos cargar tus preferencias.',
              style: MusubiType.style(
                14,
                weight: FontWeight.w600,
                line: 20,
                color: c.textSecondary,
              ),
            ),
            MusubiButton(
              label: 'Reintentar',
              icon: MusubiIcons.refreshCw,
              kind: MusubiButtonKind.secondary,
              height: MusubiSizes.buttonHeightSmall,
              onPressed: () => ref.invalidate(myProfileProvider),
            ),
          ],
        ),
      );
    } else {
      body = const SkeletonShimmer(
        child: Padding(
          key: Key('visibility-loading'),
          padding: EdgeInsets.all(14),
          child: Column(
            spacing: 24,
            children: [
              SkeletonBox(height: 32),
              SkeletonBox(height: 32),
              SkeletonBox(height: 32),
            ],
          ),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
      ),
      child: body,
    );
  }
}
