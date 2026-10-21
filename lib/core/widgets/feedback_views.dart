import 'package:flutter/material.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';

enum InlineMessageKind { error, warning, success }

/// Aviso en linea de la guia: icono + mensaje + tono propio. El error usa el
/// rojo oxido, distinto del rojo de marca.
class InlineMessage extends StatelessWidget {
  const new({
    required this.message,
    super.key,
    this.kind = InlineMessageKind.error,
    this.title,
  });

  final String message;
  final String? title;
  final InlineMessageKind kind;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final (foreground, background, icon) = switch (kind) {
      InlineMessageKind.error => (c.error, c.errorSoft, Icons.error_outline),
      InlineMessageKind.warning => (
        c.warningText,
        c.warningSoft,
        Icons.warning_amber_rounded,
      ),
      InlineMessageKind.success => (
        c.successText,
        c.successSoft,
        Icons.check_circle_outline,
      ),
    };
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(MusubiSizes.space3),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(MusubiSizes.radiusThumb),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: foreground, size: 22),
            const SizedBox(width: MusubiSizes.space2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Text(
                      title!,
                      style: textTheme.titleMedium?.copyWith(color: foreground),
                    ),
                  Text(
                    message,
                    style: textTheme.bodyMedium?.copyWith(color: foreground),
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

/// Cargando: indicador centrado con texto (RNF-12: nunca una espera muda).
class LoadingView extends StatelessWidget {
  const new({super.key, this.message = 'Cargando…'});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: MusubiSizes.space3),
        Text(message, style: Theme.of(context).textTheme.bodyMedium),
      ],
    ),
  );
}

/// Vacio: icono, titulo y explicacion (y una accion opcional).
class EmptyView extends StatelessWidget {
  const new({
    required this.title,
    required this.message,
    super.key,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(MusubiSizes.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: context.musubi.textSecondary),
            const SizedBox(height: MusubiSizes.space4),
            Text(
              title,
              style: textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MusubiSizes.space2),
            Text(
              message,
              style: textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: MusubiSizes.space6),
              MusubiButton(
                label: actionLabel!,
                onPressed: onAction,
                kind: MusubiButtonKind.secondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error con reintento (sin red o fallo del servidor).
class ErrorView extends StatelessWidget {
  const new({required this.message, required this.onRetry, super.key});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => EmptyView(
    title: 'Algo salió mal',
    message: message,
    icon: Icons.cloud_off_outlined,
    actionLabel: 'Reintentar',
    onAction: onRetry,
  );
}
