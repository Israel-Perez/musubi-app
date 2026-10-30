import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/top_bar.dart';
import 'package:musubi_app/features/auth/presentation/delete_account.dart';
import 'package:musubi_app/features/profile/presentation/settings_row.dart';

/// `Privacidad` (maqueta, HU-46): el resumen rojo, "Tus datos" y "Eliminar mi
/// cuenta". NOTE (HU-04): "Quien te ve". NOTE (HU-28): usuarios bloqueados.
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
                          color: c.onBrand,
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 6),
                  child: Text(
                    'TUS DATOS',
                    style: MusubiType.style(
                      13,
                      weight: FontWeight.w800,
                      line: 18,
                      em: 0.06,
                      color: c.textSecondary,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.border),
                  ),
                  child: SettingsRow(
                    icon: MusubiIcons.fileText,
                    title: 'Aviso de privacidad',
                    onTap: () => unawaited(context.push(AppRoutes.privacy)),
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
