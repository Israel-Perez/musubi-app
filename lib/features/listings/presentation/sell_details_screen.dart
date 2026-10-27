import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/css_line_box.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/core/widgets/musubi_text_field.dart';
import 'package:musubi_app/features/listings/presentation/sell_draft.dart';
import 'package:musubi_app/features/listings/presentation/sell_layout.dart';

/// `Vender-2`: "Cuéntanos qué es" (nombre y descripción).
class SellDetailsScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<SellDetailsScreen> createState() => _SellDetailsScreenState();
}

class _SellDetailsScreenState extends ConsumerState<SellDetailsScreen> {
  /// Maximo de la descripcion (contador "N / 500").
  static const maxDescription = 500;

  late final _title = TextEditingController(
    text: ref.read(sellDraftProvider).title,
  );
  late final _description = TextEditingController(
    text: ref.read(sellDraftProvider).description,
  );
  final _descriptionFocus = FocusNode();
  bool _titleError = false;
  Object? _shake;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _descriptionFocus.dispose();
    super.dispose();
  }

  void _continue() {
    if (!ref.read(sellDraftProvider).titleValid) {
      setState(() {
        _titleError = true;
        _shake = Object();
      });
      showSellSnack(
        context,
        'Escribe el nombre del producto',
        icon: MusubiIcons.circleAlert,
        tone: SnackTone.warn,
      );
      return;
    }
    unawaited(context.push(AppRoutes.sellPrice));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final draft = ref.watch(sellDraftProvider);
    final notifier = ref.read(sellDraftProvider.notifier);
    return SellStepLayout(
      step: 2,
      label: 'Detalles',
      title: 'Cuéntanos qué es',
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
          child: MusubiButton(label: 'Continuar', onPressed: _continue),
        ),
      ],
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 20,
            children: [
              MusubiTextField(
                label: 'Nombre del producto',
                fieldKey: const Key('sell-title'),
                controller: _title,
                textInputAction: TextInputAction.next,
                inputFormatters: [LengthLimitingTextInputFormatter(80)],
                errorText: _titleError && !draft.titleValid ? '' : null,
                shakeTrigger: _shake,
                onChanged: (value) {
                  notifier.setTitle(value);
                  if (_titleError) setState(() {});
                },
                suffix: draft.titleValid
                    ? MusubiIcon(
                        MusubiIcons.circleCheck,
                        size: 20,
                        color: c.success,
                        semanticLabel: 'Válido',
                      )
                    : null,
                footer: Row(
                  spacing: 6,
                  children: [
                    MusubiIcon(
                      MusubiIcons.check,
                      size: 15,
                      strokeWidth: 2.4,
                      color: c.successText,
                    ),
                    Expanded(
                      child: CssLineBox(
                        fontSize: 13,
                        child: Text(
                          'Incluye marca y modelo: así te encuentran más '
                          'fácil.',
                          style: MusubiType.style(
                            13,
                            weight: FontWeight.w600,
                            color: c.successText,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: CssLineBox(
                          fontSize: 13,
                          child: Text(
                            'Descripción',
                            style: MusubiType.label.copyWith(
                              color: c.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        '${draft.description.length} / $maxDescription',
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
                      key: const Key('sell-description'),
                      controller: _description,
                      focusNode: _descriptionFocus,
                      minLines: 5,
                      maxLines: 5,
                      cursorColor: c.brand,
                      textCapitalization: TextCapitalization.sentences,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(maxDescription),
                      ],
                      onChanged: notifier.setDescription,
                      style: MusubiType.style(
                        15.5,
                        line: 23,
                        color: c.textPrimary,
                      ),
                      decoration: InputDecoration.collapsed(
                        hintText: 'Estado, accesorios y cualquier detalle.',
                        hintStyle: MusubiType.style(
                          15.5,
                          line: 23,
                          color: c.placeholder,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    'Menciona el estado, los accesorios y cualquier detalle.',
                    style: MusubiType.style(13, color: c.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
