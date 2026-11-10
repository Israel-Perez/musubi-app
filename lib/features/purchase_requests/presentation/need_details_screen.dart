import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/features/listings/presentation/sell_layout.dart';
import 'package:musubi_app/features/purchase_requests/presentation/need_edit.dart';
import 'package:musubi_app/features/purchase_requests/presentation/need_widgets.dart';
import 'package:musubi_app/features/purchase_requests/presentation/wanted_providers.dart';

/// `Necesidad-2` (HU-13): descripcion (hasta 300) y caracteristicas deseadas
/// (opcionales, hasta 5).
class NeedDetailsScreen extends ConsumerStatefulWidget {
  const new({super.key, this.editing = false});

  /// "Editar solicitud" (HU-14): otro borrador, "Guardar" manda los cambios
  /// y la X vuelve a `Mis-solicitudes`.
  final bool editing;

  @override
  ConsumerState<NeedDetailsScreen> createState() => _NeedDetailsScreenState();
}

class _NeedDetailsScreenState extends ConsumerState<NeedDetailsScreen> {
  NotifierProvider<NeedDraftNotifier, NeedDraft> get _draft =>
      needDraftFor(editing: widget.editing);

  late final _description = TextEditingController(
    text: ref.read(_draft).description,
  );
  final _descriptionFocus = FocusNode();
  final _feature = TextEditingController();
  final _featureFocus = FocusNode();

  @override
  void dispose() {
    _description.dispose();
    _descriptionFocus.dispose();
    _feature.dispose();
    _featureFocus.dispose();
    super.dispose();
  }

  void _addFeature() {
    final added = ref.read(_draft.notifier).addFeature(_feature.text);
    if (added) {
      _feature.clear();
    } else if (ref.read(_draft).features.length >= NeedDraft.maxFeatures) {
      showSellSnack(
        context,
        'Puedes agregar hasta 5 características.',
        icon: MusubiIcons.info,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final draft = ref.watch(_draft);
    final notifier = ref.read(_draft.notifier);
    final fieldStyle = MusubiType.style(15.5, line: 23, color: c.textPrimary);

    return SellStepLayout(
      step: 2,
      steps: 3,
      label: 'Detalles',
      title: 'Cuéntanos más',
      subtitle: 'Mientras más claro seas, mejores ofertas recibes.',
      heading: widget.editing ? needEditHeading : 'Publicar lo que necesito',
      onSave: widget.editing
          ? () => unawaited(saveNeedEdit(context, ref))
          : () => showSellSnack(
              context,
              'Borrador guardado. Lo terminas cuando quieras desde Publicar.',
            ),
      onClose: widget.editing ? () => leaveNeedEdit(context) : null,
      actions: [
        SizedBox(
          width: 112,
          child: MusubiButton(
            label: 'Atrás',
            kind: MusubiButtonKind.secondary,
            onPressed: () => context.pop(),
          ),
        ),
        Expanded(
          child: MusubiButton(
            key: const Key('need-details-continue'),
            label: 'Continuar',
            onPressed: () => unawaited(
              context.push(
                widget.editing
                    ? AppRoutes.editNeedBudget
                    : AppRoutes.needBudget,
              ),
            ),
          ),
        ),
      ],
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(child: NeedLabel('Descripción')),
                  Text(
                    '${draft.description.length} / ${NeedDraft.maxDescription}',
                    style: MusubiType.style(
                      12,
                      weight: FontWeight.w600,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
              SellFieldBox(
                focusNode: _descriptionFocus,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: TextField(
                  key: const Key('need-description'),
                  controller: _description,
                  focusNode: _descriptionFocus,
                  minLines: 4,
                  maxLines: 4,
                  cursorColor: c.brand,
                  textCapitalization: TextCapitalization.sentences,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(NeedDraft.maxDescription),
                  ],
                  onChanged: notifier.setDescription,
                  style: fieldStyle,
                  decoration: InputDecoration.collapsed(
                    hintText:
                        'Por ejemplo: la necesito para Cálculo Integral; '
                        'puede ser usada si funciona bien.',
                    hintStyle: fieldStyle.copyWith(color: c.placeholder),
                  ),
                ),
              ),
              Text(
                '¿Para qué la necesitas? ¿Aceptas que sea usada?',
                style: MusubiType.style(13, color: c.textSecondary),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              NeedLabel(
                'Características deseadas',
                trailing: Text(
                  'Opcional',
                  style: MusubiType.style(
                    12,
                    weight: FontWeight.w600,
                    color: c.textSecondary,
                  ),
                ),
              ),
              if (draft.features.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final feature in draft.features)
                      NeedFeatureChip(
                        text: feature,
                        onRemove: () => notifier.removeFeature(feature),
                      ),
                  ],
                ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: SellFieldBox(
                  focusNode: _featureFocus,
                  height: MusubiSizes.fieldHeight,
                  padding: const EdgeInsets.only(left: 14, right: 4),
                  child: Row(
                    spacing: 6,
                    children: [
                      Expanded(
                        child: TextField(
                          key: const Key('need-feature'),
                          controller: _feature,
                          focusNode: _featureFocus,
                          cursorColor: c.brand,
                          textInputAction: TextInputAction.done,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(
                              NeedDraft.maxFeature,
                            ),
                          ],
                          onSubmitted: (_) => _addFeature(),
                          style: MusubiType.style(15, color: c.textPrimary),
                          decoration: InputDecoration.collapsed(
                            hintText: 'Agrega otra, por ejemplo: con manual',
                            hintStyle: MusubiType.style(
                              15,
                              color: c.placeholder,
                            ),
                          ),
                        ),
                      ),
                      Pressable(
                        key: const Key('need-feature-add'),
                        onTap: _addFeature,
                        semanticLabel: 'Agregar característica',
                        builder: (context, _) => SizedBox.square(
                          dimension: MusubiSizes.minTouch,
                          child: Center(
                            child: MusubiIcon(
                              MusubiIcons.plus,
                              size: 22,
                              strokeWidth: 2.2,
                              color: c.brand,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
