import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_panel.dart';
import 'package:musubi_app/features/profile/domain/profile_models.dart';
import 'package:musubi_app/features/profile/presentation/profile_providers.dart';
import 'package:musubi_app/features/profile/presentation/profile_screen.dart';

/// "Correo institucional" (maqueta `Ajustes`, `aj-correo`): correo, estado
/// "Verificado" y desde cuando. No se puede cambiar.
Future<void> showEmailSheet(BuildContext context) =>
    showMusubiPanel<void>(context, builder: (_) => const EmailSheet());

class EmailSheet extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.musubi;
    final me = ref.watch(myProfileProvider).value;
    final email = me?.email ?? sessionProfile(ref)?.email ?? '';
    final verifiedAt = me?.emailVerifiedAt;
    return MusubiPanel(
      key: const Key('email-sheet'),
      title: 'Correo institucional',
      actions: [
        MusubiButton(
          label: 'Entendido',
          height: MusubiSizes.buttonHeightSheet,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PanelCard(
            rows: [
              ('Correo', email, null),
              ('Estado', 'Verificado', c.successText),
              if (verifiedAt != null) ('Desde', monthYear(verifiedAt), null),
            ],
          ),
          const PanelNote(
            'Tu correo de la universidad es lo que te identifica como parte '
            'de la comunidad. No se puede cambiar.',
          ),
        ],
      ),
    );
  }
}
