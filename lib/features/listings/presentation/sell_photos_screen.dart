import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/css_dashes.dart';
import 'package:musubi_app/core/widgets/feedback_views.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/core/widgets/shake.dart';
import 'package:musubi_app/features/listings/data/photo_picker.dart';
import 'package:musubi_app/features/listings/presentation/listings_providers.dart';
import 'package:musubi_app/features/listings/presentation/sell_draft.dart';
import 'package:musubi_app/features/listings/presentation/sell_layout.dart';

/// `Vender-1`: "Agrega fotos". La primera es la portada; hasta 8.
class SellPhotosScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<SellPhotosScreen> createState() => _SellPhotosScreenState();
}

class _SellPhotosScreenState extends ConsumerState<SellPhotosScreen> {
  Object? _shake;

  SellDraftNotifier get _draft => ref.read(sellDraftProvider.notifier);

  Future<void> _camera() async {
    try {
      final path = await ref.read(photoPickerProvider).takePhoto();
      if (path == null || !mounted) return;
      _draft.addPhotos([path]);
      showSellSnack(
        context,
        'Foto agregada',
        icon: MusubiIcons.camera,
        duration: const Duration(milliseconds: 1600),
      );
    } on PhotoPickFailure {
      if (mounted) _pickFailed('No pudimos abrir la cámara.');
    }
  }

  Future<void> _gallery() async {
    try {
      final room = ref.read(sellDraftProvider).room;
      final paths = await ref
          .read(photoPickerProvider)
          .pickFromGallery(max: room);
      if (paths.isEmpty || !mounted) return;
      final added = _draft.addPhotos(paths);
      showSellSnack(
        context,
        added > 1 ? 'Agregaste $added fotos' : 'Agregaste una foto',
        icon: MusubiIcons.image,
      );
    } on PhotoPickFailure {
      if (mounted) _pickFailed('No pudimos abrir tu galería.');
    }
  }

  void _pickFailed(String message) => showSellSnack(
    context,
    message,
    icon: MusubiIcons.circleAlert,
    tone: SnackTone.warn,
  );

  void _remove(DraftPhoto photo) {
    final removed = _draft.removePhoto(photo.id);
    if (removed == null) return;
    final (index, _) = removed;
    showSellSnack(
      context,
      'Quitaste la foto ${index + 1}',
      icon: MusubiIcons.image,
      tone: SnackTone.info,
      actionLabel: 'Deshacer',
      onAction: () => _draft.restorePhoto(index, photo),
    );
  }

  void _continue() {
    if (ref.read(sellDraftProvider).photos.isEmpty) {
      setState(() => _shake = Object());
      showSellSnack(
        context,
        'Agrega al menos una foto para continuar',
        icon: MusubiIcons.camera,
        tone: SnackTone.warn,
      );
      return;
    }
    unawaited(context.push(AppRoutes.sellDetails));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final draft = ref.watch(sellDraftProvider);
    final photos = draft.photos;
    return SellStepLayout(
      step: 1,
      label: 'Fotos',
      title: 'Agrega fotos',
      subtitle: 'La primera será la portada. Puedes subir hasta 8.',
      actions: [
        Expanded(
          child: MusubiButton(label: 'Continuar', onPressed: _continue),
        ),
      ],
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final side = (constraints.maxWidth - 20) / 3;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (var i = 0; i < photos.length; i++)
                    SizedBox.square(
                      key: ValueKey('sell-photo-${photos[i].id}'),
                      dimension: side,
                      child: _PhotoSlot(
                        index: i,
                        photo: photos[i],
                        size: side,
                        onRemove: () => _remove(photos[i]),
                        onRetry: () => _draft.retry(photos[i].id),
                        onMove: _draft.movePhoto,
                      ),
                    ),
                  if (draft.room > 0) ...[
                    SizedBox.square(
                      dimension: side,
                      child: Shake(
                        trigger: _shake,
                        pattern: ShakePattern.field,
                        child: _AddTile(
                          key: const Key('sell-camera'),
                          icon: MusubiIcons.camera,
                          label: 'Tomar foto',
                          onTap: () => unawaited(_camera()),
                        ),
                      ),
                    ),
                    SizedBox.square(
                      dimension: side,
                      child: _AddTile(
                        key: const Key('sell-gallery'),
                        icon: MusubiIcons.image,
                        label: 'Galería',
                        onTap: () => unawaited(_gallery()),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Mantén presionada una foto para reordenarla',
                  style: MusubiType.style(
                    12.5,
                    weight: FontWeight.w600,
                    color: c.textSecondary,
                  ),
                ),
              ),
              Text(
                '${photos.length} de ${SellDraft.maxPhotos}',
                style: MusubiType.style(
                  12.5,
                  weight: FontWeight.w800,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const _PhotoTips(),
      ],
    );
  }
}

/// Foto del borrador: portada, quitar, reordenar y estado de la subida.
class _PhotoSlot extends StatelessWidget {
  const new({
    required this.index,
    required this.photo,
    required this.size,
    required this.onRemove,
    required this.onRetry,
    required this.onMove,
  });

  final int index;
  final DraftPhoto photo;
  final double size;
  final VoidCallback onRemove;
  final VoidCallback onRetry;
  final void Function(int from, int to) onMove;

  @override
  Widget build(BuildContext context) {
    final tile = _PhotoTile(
      index: index,
      photo: photo,
      onRemove: onRemove,
      onRetry: onRetry,
    );
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data != index,
      onAcceptWithDetails: (details) => onMove(details.data, index),
      builder: (context, candidates, _) => LongPressDraggable<int>(
        data: index,
        feedback: SizedBox.square(
          dimension: size,
          child: Opacity(opacity: 0.9, child: tile),
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: tile),
        child: AnimatedScale(
          scale: candidates.isEmpty ? 1 : 0.94,
          duration: const Duration(milliseconds: 150),
          child: tile,
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const new({
    required this.index,
    required this.photo,
    required this.onRemove,
    required this.onRetry,
  });

  final int index;
  final DraftPhoto photo;
  final VoidCallback onRemove;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return PopIn(
      from: 0.92,
      duration: const Duration(milliseconds: 350),
      curve: Curves.ease,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(MusubiSizes.radiusButton),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: c.surface,
              child: Image.file(
                File(photo.path),
                fit: BoxFit.cover,
                semanticLabel: 'Foto ${index + 1}',
                errorBuilder: (_, _, _) => const SizedBox.expand(),
              ),
            ),
            if (photo.upload != PhotoUpload.done)
              ColoredBox(
                color: const Color(0x661C1C1E),
                child: Center(
                  child: photo.upload == PhotoUpload.uploading
                      ? const MusubiSpinner(color: Color(0xFFFFFFFF))
                      : Pressable(
                          onTap: onRetry,
                          semanticLabel:
                              'Reintentar subir la foto ${index + 1}',
                          builder: (context, _) => const SizedBox.square(
                            dimension: MusubiSizes.minTouch,
                            child: Center(
                              child: MusubiIcon(
                                MusubiIcons.refreshCw,
                                size: 22,
                                color: Color(0xFFFFFFFF),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            if (index == 0)
              Positioned(
                left: 6,
                bottom: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: c.inverse,
                    borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
                  ),
                  child: Text(
                    'Portada',
                    style: MusubiType.style(
                      10.5,
                      weight: FontWeight.w800,
                      color: const Color(0xFFFFFFFF),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 0,
              right: 0,
              child: Pressable(
                onTap: onRemove,
                semanticLabel: 'Quitar foto ${index + 1}',
                builder: (context, _) => SizedBox.square(
                  dimension: 40,
                  child: Center(
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Color(0xB81C1C1E),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: MusubiIcon(
                          MusubiIcons.x,
                          size: 13,
                          strokeWidth: 2.4,
                          color: Color(0xFFFFFFFF),
                        ),
                      ),
                    ),
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

/// "Tomar foto" / "Galería": recuadro de borde punteado.
class _AddTile extends StatelessWidget {
  const new({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final MusubiIconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Pressable(
      onTap: onTap,
      pressScale: 0.97,
      semanticLabel: label,
      builder: (context, pressed) => CustomPaint(
        foregroundPainter: _DashedBorderPainter(color: c.neutralStrong),
        child: Container(
          decoration: BoxDecoration(
            color: pressed ? c.surface : c.background,
            borderRadius: BorderRadius.circular(MusubiSizes.radiusButton),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 6,
            children: [
              MusubiIcon(icon, strokeWidth: 1.9, color: c.brandText),
              Text(
                label,
                style: MusubiType.style(
                  12.5,
                  weight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `border: 1.5px dashed` con radio 16, con el patron de guiones de Chrome.
class _DashedBorderPainter extends CustomPainter {
  const new({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = cssDashThickness / 2;
    final rect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(inset),
      const Radius.circular(MusubiSizes.radiusButton - inset),
    );
    final path = Path()..addRRect(rect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = cssDashThickness;
    for (final metric in path.computeMetrics()) {
      for (final (start, end) in cssDashSegments(0, metric.length)) {
        canvas.drawPath(metric.extractPath(start, end), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// "Fotos que venden más rápido".
class _PhotoTips extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    Widget tip(String text) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 16,
          child: Text(
            '•',
            style: MusubiType.style(13, line: 18, color: c.textPrimary),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: MusubiType.style(13, line: 18, color: c.textPrimary),
          ),
        ),
      ],
    );
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(MusubiSizes.radiusButton),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c.elevated,
              borderRadius: BorderRadius.circular(MusubiSizes.radiusThumb),
            ),
            child: Center(
              child: MusubiIcon(
                MusubiIcons.lightbulb,
                size: 20,
                strokeWidth: 1.9,
                color: c.warningText,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                Text(
                  'Fotos que venden más rápido',
                  style: MusubiType.style(
                    14,
                    weight: FontWeight.w800,
                    color: c.textPrimary,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 3,
                  children: [
                    tip('Usa luz natural y un fondo liso.'),
                    tip('Muestra cualquier detalle o rayón.'),
                    tip('Incluye accesorios: tapa, cargador o funda.'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
