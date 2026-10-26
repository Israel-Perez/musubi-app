import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/features/auth/presentation/account_gate.dart';

/// Campus que ve un visitante. NOTE (HU-48): con mas comunidades activas
/// (RNF-21), el visitante elige campus y el de la cuenta sale de su correo.
abstract final class DefaultCampus {
  static const shortName = 'UTTT';
  static const place = 'Tula-Tepeji, Hidalgo';
  static const domain = 'uttt.edu.mx';
}

/// Chip "UTTT" junto al logo (maqueta: visitante con flecha, con sesion con
/// la palomita de verificado). Abre la hoja del campus.
class CampusChip extends ConsumerWidget {
  const new({required this.signedIn, super.key});

  final bool signedIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.musubi;
    return Semantics(
      button: true,
      label: 'Campus ${DefaultCampus.shortName}',
      excludeSemantics: true,
      child: Material(
        color: c.surface,
        shape: const StadiumBorder(),
        child: InkWell(
          key: const Key('campus-chip'),
          customBorder: const StadiumBorder(),
          onTap: () => showModalBottomSheet<void>(
            context: context,
            useRootNavigator: true,
            isScrollControlled: true,
            showDragHandle: true,
            backgroundColor: c.background,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(MusubiSizes.radiusSheet),
              ),
            ),
            builder: (_) => _CampusSheet(signedIn: signedIn),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _CampusBadge(size: 26),
                const SizedBox(width: 6),
                Text(
                  DefaultCampus.shortName,
                  style: MusubiType.label.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  signedIn ? Icons.verified : Icons.keyboard_arrow_down,
                  size: signedIn ? 15 : 18,
                  color: signedIn ? c.brandText : c.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CampusBadge extends StatelessWidget {
  const new({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: c.brand, shape: BoxShape.circle),
      child: Icon(Icons.school, size: size * 0.55, color: c.onBrand),
    );
  }
}

/// "Estás explorando la UTTT" (visitante) o el campus de tu cuenta.
class _CampusSheet extends ConsumerWidget {
  const new({required this.signedIn});

  final bool signedIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.musubi;
    final textTheme = Theme.of(context).textTheme;

    final campusCard = Container(
      padding: const EdgeInsets.all(MusubiSizes.space4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(MusubiSizes.radiusButton),
      ),
      child: Row(
        children: [
          const _CampusBadge(size: 44),
          const SizedBox(width: MusubiSizes.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DefaultCampus.shortName, style: textTheme.titleMedium),
                Text(
                  DefaultCampus.place,
                  style: textTheme.bodySmall?.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
          Text.rich(
            TextSpan(
              style: MusubiType.label.copyWith(color: c.textSecondary),
              children: [
                const TextSpan(text: 'tu.nombre'),
                TextSpan(
                  text: '@uttt',
                  style: TextStyle(
                    color: c.brandText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const TextSpan(text: '.edu.mx'),
              ],
            ),
          ),
        ],
      ),
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          MusubiSizes.gutter,
          0,
          MusubiSizes.gutter,
          MusubiSizes.space4,
        ),
        child: Column(
          key: const Key('campus-sheet'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            campusCard,
            const SizedBox(height: MusubiSizes.space4),
            Text(
              signedIn
                  ? 'Tu campus es la ${DefaultCampus.shortName}'
                  : 'Estás explorando la ${DefaultCampus.shortName}',
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(fontSize: 22),
            ),
            const SizedBox(height: MusubiSizes.space1),
            Text(
              signedIn
                  ? 'Lo detectamos con tu correo institucional. Solo ves y '
                        'publicas en tu comunidad.'
                  : 'Tu campus se fija con tu correo institucional.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: MusubiSizes.space4),
            Center(
              child: Container(
                padding: const EdgeInsets.fromLTRB(6, 5, 14, 5),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CampusAvatars(size: 26),
                    const SizedBox(width: 10),
                    Text(
                      'Solo con tu correo @${DefaultCampus.domain}',
                      style: MusubiType.label.copyWith(color: c.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: MusubiSizes.space6),
            if (signedIn)
              MusubiButton(
                label: 'Entendido',
                onPressed: () => Navigator.of(context).pop(),
              )
            else ...[
              MusubiButton(
                label: 'Crear cuenta',
                onPressed: () => continueToAccount(
                  context,
                  ref,
                  route: AppRoutes.signUp,
                  returnTo: AppRoutes.home,
                ),
              ),
              const SizedBox(height: MusubiSizes.space2),
              MusubiButton(
                label: 'Ya tengo cuenta',
                kind: MusubiButtonKind.secondary,
                onPressed: () => continueToAccount(
                  context,
                  ref,
                  route: AppRoutes.signIn,
                  returnTo: AppRoutes.home,
                ),
              ),
              MusubiButton(
                label: 'Seguir explorando',
                kind: MusubiButtonKind.text,
                onPressed: () => Navigator.of(context).pop(),
              ),
              Text(
                'Al entrar, vuelves justo aquí.',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(color: c.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Avatares de muestra de la maqueta (iniciales ficticias de la comunidad).
class CampusAvatars extends StatelessWidget {
  const new({this.size = 32, this.border, super.key});

  final double size;
  final Color? border;

  static const _people = [
    ('VC', Color(0xFFE9E2F3), Color(0xFF5B3E86)),
    ('PN', Color(0xFFFBE3D6), Color(0xFF8A3E17)),
    ('JS', Color(0xFFDCEBF7), Color(0xFF1F4E79)),
    ('DH', Color(0xFFDDEBDD), Color(0xFF2F5D34)),
  ];

  @override
  Widget build(BuildContext context) {
    final ring = border ?? context.musubi.surface;
    return ExcludeSemantics(
      child: SizedBox(
        height: size,
        width: size + (_people.length - 1) * (size - 8),
        child: Stack(
          children: [
            for (var i = 0; i < _people.length; i++)
              Positioned(
                left: i * (size - 8),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: _people[i].$2,
                    shape: BoxShape.circle,
                    border: Border.all(color: ring, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _people[i].$1,
                    style: TextStyle(
                      fontFamily: MusubiType.family,
                      fontSize: size * 0.34,
                      fontWeight: FontWeight.w800,
                      color: _people[i].$3,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
