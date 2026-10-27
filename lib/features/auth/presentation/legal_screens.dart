import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/feedback_views.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/features/auth/presentation/auth_layout.dart';

/// Documentos legales (HU-47). Fuente unica: `assets/legal/*.md` (la landing
/// publica los mismos archivos).
abstract final class LegalDocuments {
  static const privacy = 'assets/legal/aviso-de-privacidad.md';
  static const terms = 'assets/legal/terminos-y-condiciones.md';
}

/// Texto de un documento legal empaquetado en la app.
final FutureProviderFamily<String, String> legalDocumentProvider =
    FutureProvider.family<String, String>(
      (ref, asset) => rootBundle.loadString(asset),
    );

void _leave(BuildContext context) =>
    context.canPop() ? context.pop() : context.go(AppRoutes.home);

/// "Aviso de privacidad · Resumen" de la maqueta (`Aviso-privacidad`) y,
/// debajo, el aviso integral.
class PrivacyNoticeScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    const summary = [
      (
        MusubiIcons.database,
        'Qué guardamos',
        'Tu nombre, tu correo institucional y lo que publicas.',
      ),
      (
        MusubiIcons.graduationCap,
        'Para qué',
        'Confirmar que eres estudiante y conectar compras.',
      ),
      (
        MusubiIcons.ban,
        'Qué no hacemos',
        'No vendemos tus datos ni guardamos tu tarjeta.',
      ),
      (
        MusubiIcons.penLine,
        'Tus derechos',
        'Ver, corregir o borrar tus datos cuando quieras.',
      ),
    ];

    Widget card(int i) {
      final (icon, title, text) = summary[i];
      final highlight = i == 2;
      return RiseIn(
        delay: Duration(milliseconds: 50 * (i + 1)),
        child: Container(
          padding: const EdgeInsets.all(MusubiSizes.space4),
          decoration: BoxDecoration(
            color: highlight ? c.brandSoft : c.surface,
            borderRadius: BorderRadius.circular(MusubiSizes.radiusWanted),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: highlight ? c.brand : c.background,
                  borderRadius: BorderRadius.circular(MusubiSizes.radiusField),
                ),
                child: Center(
                  child: MusubiIcon(
                    icon,
                    size: 21,
                    strokeWidth: 1.9,
                    color: highlight ? c.onBrand : c.textPrimary,
                  ),
                ),
              ),
              Text(
                title,
                style: MusubiType.style(
                  15.5,
                  weight: FontWeight.w800,
                  line: 20,
                  color: c.textPrimary,
                ),
              ),
              Text(
                text,
                style: MusubiType.style(13, line: 18, color: c.textTertiary),
              ),
            ],
          ),
        ),
      );
    }

    return AuthLayout(
      onBack: () => _leave(context),
      bottom: 34,
      actions: [
        MusubiButton(label: 'Entendido', onPressed: () => _leave(context)),
      ],
      children: [
        const _LegalHeading(
          icon: MusubiIcons.shieldCheck,
          title: 'Aviso de privacidad',
          caption: 'Resumen · Actualizado en octubre de 2026',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
          child: Column(
            spacing: 10,
            children: [
              for (final pair in [
                [0, 1],
                [2, 3],
              ])
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 10,
                    children: [for (final i in pair) Expanded(child: card(i))],
                  ),
                ),
            ],
          ),
        ),
        Container(
          key: const Key('privacy-campus-only'),
          margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.border),
          ),
          child: Row(
            spacing: MusubiSizes.space3,
            children: [
              MusubiIcon(
                MusubiIcons.graduationCap,
                size: 20,
                color: c.textPrimary,
              ),
              Expanded(
                child: Text(
                  'Tu perfil solo lo ve gente de la UTTT.',
                  style: MusubiType.style(
                    13.5,
                    weight: FontWeight.w600,
                    line: 19,
                    color: c.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 28, 20, 0),
          child: LegalDocumentView(asset: LegalDocuments.privacy),
        ),
      ],
    );
  }
}

/// Terminos y condiciones completos.
class TermsScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => AuthLayout(
    onBack: () => _leave(context),
    bottom: 34,
    actions: [
      MusubiButton(label: 'Entendido', onPressed: () => _leave(context)),
    ],
    children: const [
      _LegalHeading(
        icon: MusubiIcons.fileText,
        title: 'Términos y condiciones',
        caption: 'Actualizado en octubre de 2026',
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(20, 22, 20, 0),
        child: LegalDocumentView(asset: LegalDocuments.terms, skipTitle: true),
      ),
    ],
  );
}

/// Icono de 60 en su cuadro rojo claro, titulo de 28 y fecha.
class _LegalHeading extends StatelessWidget {
  const new({required this.icon, required this.title, required this.caption});

  final MusubiIconData icon;
  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: MusubiSizes.space3,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: c.brandSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: MusubiIcon(
                icon,
                size: 30,
                strokeWidth: 1.9,
                color: c.brandText,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: MusubiType.style(
                    28,
                    weight: FontWeight.w800,
                    line: 34,
                    em: -0.03,
                    color: c.textPrimary,
                  ),
                ),
              ),
              Text(
                caption,
                style: MusubiType.style(
                  13.5,
                  weight: FontWeight.w600,
                  line: 18,
                  color: c.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Muestra un documento en el Markdown minimo de `assets/legal/`:
/// `#` titulo, `##` seccion, `-` vineta y parrafos.
class LegalDocumentView extends ConsumerWidget {
  const new({required this.asset, super.key, this.skipTitle = false});

  final String asset;

  /// Sin el `#` del documento (la pantalla ya lo muestra).
  final bool skipTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.musubi;
    final paragraph = MusubiType.style(14.5, line: 21, color: c.textSecondary);
    return switch (ref.watch(legalDocumentProvider(asset))) {
      AsyncData(:final value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in value.split('\n'))
            if (line.startsWith('# ')) ...[
              if (!skipTitle)
                Padding(
                  padding: const EdgeInsets.only(bottom: MusubiSizes.space2),
                  child: Text(
                    line.substring(2),
                    style: MusubiType.style(
                      20,
                      weight: FontWeight.w800,
                      line: 26,
                      em: -0.02,
                      color: c.textPrimary,
                    ),
                  ),
                ),
            ] else if (line.startsWith('## '))
              Padding(
                padding: const EdgeInsets.only(top: 18, bottom: 6),
                child: Text(
                  line.substring(3),
                  style: MusubiType.style(
                    16,
                    weight: FontWeight.w800,
                    line: 21,
                    color: c.textPrimary,
                  ),
                ),
              )
            else if (line.startsWith('- '))
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: c.brandText,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Expanded(child: Text(line.substring(2), style: paragraph)),
                  ],
                ),
              )
            else if (line.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: MusubiSizes.space2),
                child: Text(line, style: paragraph),
              ),
        ],
      ),
      AsyncError() => const InlineMessage(
        message: 'No pudimos abrir el documento. Inténtalo de nuevo.',
      ),
      _ => const LoadingView(message: 'Abriendo documento…'),
    };
  }
}
