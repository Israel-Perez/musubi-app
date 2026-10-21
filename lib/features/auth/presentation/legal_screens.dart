import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/feedback_views.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';

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

/// "Aviso de privacidad · Resumen" de la maqueta + el aviso integral.
class PrivacyNoticeScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final c = context.musubi;
    const summary = [
      (
        'Qué guardamos',
        'Tu nombre, tu correo institucional y lo que publicas.',
      ),
      ('Para qué', 'Confirmar que eres estudiante y conectar compras.'),
      ('Qué no hacemos', 'No vendemos tus datos ni guardamos tu tarjeta.'),
      ('Tus derechos', 'Ver, corregir o borrar tus datos cuando quieras.'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Aviso de privacidad')),
      body: ListView(
        padding: const EdgeInsets.all(MusubiSizes.gutter),
        children: [
          Text(
            'Resumen · Actualizado en octubre de 2026',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: MusubiSizes.space4),
          for (final (title, text) in summary) ...[
            Text(title, style: textTheme.titleMedium),
            const SizedBox(height: MusubiSizes.space1),
            Text(text, style: textTheme.bodyLarge),
            const SizedBox(height: MusubiSizes.space4),
          ],
          const InlineMessage(
            kind: InlineMessageKind.success,
            message: 'Tu perfil solo lo ve gente de tu campus.',
            key: Key('privacy-campus-only'),
          ),
          const SizedBox(height: MusubiSizes.space6),
          Divider(color: c.border),
          const SizedBox(height: MusubiSizes.space4),
          const LegalDocumentView(asset: LegalDocuments.privacy),
          const SizedBox(height: MusubiSizes.space6),
          MusubiButton(
            label: 'Entendido',
            onPressed: () => context.canPop() ? context.pop() : null,
          ),
        ],
      ),
    );
  }
}

/// Terminos y condiciones completos.
class TermsScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Términos y condiciones')),
    body: ListView(
      padding: const EdgeInsets.all(MusubiSizes.gutter),
      children: const [LegalDocumentView(asset: LegalDocuments.terms)],
    ),
  );
}

/// Muestra un documento en el Markdown minimo de `assets/legal/`:
/// `#` titulo, `##` seccion, `-` vineta y parrafos.
class LegalDocumentView extends ConsumerWidget {
  const new({required this.asset, super.key});

  final String asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    return switch (ref.watch(legalDocumentProvider(asset))) {
      AsyncData(:final value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in value.split('\n'))
            if (line.startsWith('# '))
              Padding(
                padding: const EdgeInsets.only(bottom: MusubiSizes.space2),
                child: Text(line.substring(2), style: textTheme.titleLarge),
              )
            else if (line.startsWith('## '))
              Padding(
                padding: const EdgeInsets.only(
                  top: MusubiSizes.space4,
                  bottom: MusubiSizes.space1,
                ),
                child: Text(line.substring(3), style: textTheme.titleMedium),
              )
            else if (line.startsWith('- '))
              Padding(
                padding: const EdgeInsets.only(left: MusubiSizes.space2),
                child: Text(
                  '•  ${line.substring(2)}',
                  style: textTheme.bodyLarge,
                ),
              )
            else if (line.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: MusubiSizes.space2),
                child: Text(line, style: textTheme.bodyLarge),
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
