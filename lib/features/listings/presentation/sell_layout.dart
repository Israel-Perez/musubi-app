import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_sheet.dart';
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/core/widgets/top_bar.dart';
import 'package:musubi_app/features/listings/presentation/sell_draft.dart';

/// Alto de la barra de acciones de `Vender-1…4` (12 + 56 + 30), para subir
/// los avisos breves.
const sellActionsHeight = 98.0;

/// Avisos del flujo de venta, encima de la barra de acciones.
void showSellSnack(
  BuildContext context,
  String message, {
  MusubiIconData icon = MusubiIcons.check,
  SnackTone tone = SnackTone.success,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 3),
}) => showMusubiSnack(
  ScaffoldMessenger.of(context),
  message,
  icon: icon,
  tone: tone,
  actionLabel: actionLabel,
  onAction: onAction,
  bottomOffset: sellActionsHeight,
  duration: duration,
);

/// Pantalla de un paso de "Vender un producto" (maqueta `Vender-1…4`):
/// cerrar, titulo y "Guardar"; barra de 4 pasos; "Paso N de 4 · X"; titulo;
/// contenido con scroll y las acciones fijas abajo.
class SellStepLayout extends ConsumerWidget {
  const new({
    required this.step,
    required this.label,
    required this.title,
    required this.children,
    required this.actions,
    super.key,
    this.subtitle,
  });

  /// 1 a 4.
  final int step;

  /// "Fotos", "Detalles", "Precio", "Último paso".
  final String label;
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.musubi;
    final bottom = math.max(30, MediaQuery.viewPaddingOf(context).bottom + 6);
    return Scaffold(
      backgroundColor: c.background,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: _SellHeader(
              onClose: () => context.go(AppRoutes.home),
              onSave: () {
                ref.read(sellDraftProvider.notifier).save();
                showSellSnack(
                  context,
                  'Borrador guardado. Lo terminas cuando quieras desde '
                  'Publicar.',
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
            child: SellProgress(step: step),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 6,
                      children: [
                        Eyebrow('Paso $step de 4 · $label'),
                        Semantics(
                          header: true,
                          child: Text(
                            title,
                            style: MusubiType.style(
                              26,
                              weight: FontWeight.w800,
                              line: 32,
                              em: -0.025,
                              color: c.textPrimary,
                            ),
                          ),
                        ),
                        if (subtitle case final subtitle?)
                          Text(
                            subtitle,
                            style: MusubiType.body.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  ...children,
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: c.background,
              border: Border(top: BorderSide(color: c.border)),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, bottom.toDouble()),
              child: Row(spacing: 10, children: actions),
            ),
          ),
        ],
      ),
    );
  }
}

class _SellHeader extends StatelessWidget {
  const new({required this.onClose, required this.onSave});

  final VoidCallback onClose;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Pressable(
            onTap: onClose,
            semanticLabel: 'Cerrar',
            builder: (context, _) => SizedBox.square(
              dimension: MusubiSizes.minTouch,
              child: Center(
                child: MusubiIcon(
                  MusubiIcons.x,
                  size: 22,
                  color: c.textPrimary,
                ),
              ),
            ),
          ),
          Flexible(
            child: Text(
              'Vender un producto',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: MusubiType.style(
                16,
                weight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
          ),
          Pressable(
            key: const Key('sell-save'),
            onTap: onSave,
            semanticLabel: 'Guardar borrador',
            builder: (context, pressed) => Container(
              height: MusubiSizes.minTouch,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              child: Text(
                'Guardar',
                style: MusubiType.style(
                  14,
                  weight: FontWeight.w700,
                  color: pressed ? c.textPrimary : c.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra de 4 pasos (`role=progressbar`): los anteriores en rojo y el actual
/// se llena en 0.6 s.
class SellProgress extends StatelessWidget {
  const new({required this.step, super.key});

  final int step;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final animate = !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    return Semantics(
      label: 'Paso $step de 4',
      child: Row(
        spacing: 6,
        children: [
          for (var i = 1; i <= 4; i++)
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: SizedBox(
                  height: 4,
                  child: ColoredBox(
                    color: i < step ? c.brand : c.border,
                    child: i == step
                        ? TweenAnimationBuilder<double>(
                            tween: Tween(begin: animate ? 0 : 1, end: 1),
                            duration: const Duration(milliseconds: 600),
                            curve: musubiEaseOut,
                            builder: (context, t, _) => FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: t,
                              child: ColoredBox(color: c.brand),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Caja de un campo de la maqueta (`Vender-2/3`): borde de 1.5, halo rojo
/// suave al enfocar y rojo oxido con error.
class SellFieldBox extends StatefulWidget {
  const new({
    required this.focusNode,
    required this.child,
    super.key,
    this.error = false,
    this.radius = MusubiSizes.radiusField,
    this.height,
    this.padding = EdgeInsets.zero,
  });

  final FocusNode focusNode;
  final Widget child;
  final bool error;
  final double radius;
  final double? height;
  final EdgeInsets padding;

  @override
  State<SellFieldBox> createState() => _SellFieldBoxState();
}

class _SellFieldBoxState extends State<SellFieldBox> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_changed);
  }

  @override
  void didUpdateWidget(SellFieldBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_changed);
      widget.focusNode.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_changed);
    super.dispose();
  }

  void _changed() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final focused = widget.focusNode.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: widget.height,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: BorderRadius.circular(widget.radius),
        border: Border.all(
          color: widget.error
              ? c.error
              : focused
              ? c.brandBorder
              : c.border,
          width: 1.5,
        ),
        boxShadow: focused && !widget.error
            ? [BoxShadow(color: c.brandSoft, spreadRadius: 4)]
            : null,
      ),
      child: widget.child,
    );
  }
}
