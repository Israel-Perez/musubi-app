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
import 'package:musubi_app/core/widgets/musubi_text_field.dart';
import 'package:musubi_app/features/listings/presentation/listings_providers.dart';
import 'package:musubi_app/features/listings/presentation/sell_layout.dart';
import 'package:musubi_app/features/purchase_requests/presentation/need_widgets.dart';
import 'package:musubi_app/features/purchase_requests/presentation/wanted_providers.dart';

/// `Necesidad-1` (HU-13): "Así funciona", el producto que se busca y su
/// categoria. "Ya hay N publicaciones parecidas" sale de la busqueda (HU-09).
class NeedProductScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<NeedProductScreen> createState() => _NeedProductScreenState();
}

class _NeedProductScreenState extends ConsumerState<NeedProductScreen> {
  late final _title = TextEditingController(
    text: ref.read(needDraftProvider).title,
  );
  Timer? _debounce;
  String _query = '';
  String? _titleError;
  String? _categoryError;
  int _shake = 0;

  @override
  void initState() {
    super.initState();
    _query = _title.text;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _title.dispose();
    super.dispose();
  }

  void _changed(String value) {
    ref.read(needDraftProvider.notifier).setTitle(value);
    if (_titleError != null && value.trim().length >= NeedDraft.minTitle) {
      setState(() => _titleError = null);
    }
    // Busca coincidencias medio segundo despues de dejar de escribir.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _query = value);
    });
  }

  void _continue() {
    final draft = ref.read(needDraftProvider);
    setState(() {
      _titleError = draft.titleValid
          ? null
          : 'Escribe qué buscas, con al menos 3 letras.';
      _categoryError = draft.category == null ? 'Elige una categoría.' : null;
      if (_titleError != null) _shake++;
    });
    if (_titleError == null && _categoryError == null) {
      unawaited(context.push(AppRoutes.needDetails));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final draft = ref.watch(needDraftProvider);
    final categories = ref.watch(sellCategoriesProvider);
    final matches = ref.watch(needMatchesProvider(_query)).value ?? const [];

    return SellStepLayout(
      step: 1,
      steps: 3,
      label: 'Producto',
      title: '¿Qué estás buscando?',
      heading: 'Publicar lo que necesito',
      onSave: () => showSellSnack(
        context,
        'Borrador guardado. Lo terminas cuando quieras desde Publicar.',
      ),
      top: const NeedHowItWorks(),
      actions: [
        Expanded(
          child: MusubiButton(
            key: const Key('need-continue'),
            label: 'Continuar',
            onPressed: _continue,
          ),
        ),
      ],
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: MusubiTextField(
            label: 'Producto que buscas',
            fieldKey: const Key('need-title'),
            controller: _title,
            errorText: _titleError,
            shakeTrigger: _shake,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              LengthLimitingTextInputFormatter(NeedDraft.maxTitle),
            ],
            onChanged: _changed,
            suffix: draft.titleValid
                ? MusubiIcon(
                    MusubiIcons.circleCheck,
                    size: 20,
                    color: c.success,
                  )
                : null,
            footer: Text(
              'Sé específico: el modelo, la edición o la talla ayudan a '
              'encontrar coincidencias.',
              style: MusubiType.style(13, line: 18, color: c.textSecondary),
            ),
          ),
        ),
        // `<legend>` de un `<fieldset>` en la maqueta: el navegador lo pega
        // al texto de arriba y deja el relleno (18) bajo el, con su margen (6).
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 6 + 18),
                child: NeedLabel('Categoría'),
              ),
              switch (categories) {
                AsyncData(:final value) => Wrap(
                  spacing: 8,
                  children: [
                    for (final category in [...value, otherCategory])
                      NeedChip(
                        key: Key('need-category-${category.slug}'),
                        label: category.name,
                        selected: draft.category?.slug == category.slug,
                        onTap: () {
                          ref
                              .read(needDraftProvider.notifier)
                              .setCategory(category);
                          setState(() => _categoryError = null);
                        },
                      ),
                  ],
                ),
                AsyncError() => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text(
                      'No pudimos cargar las categorías.',
                      style: MusubiType.style(
                        14,
                        weight: FontWeight.w600,
                        color: c.textSecondary,
                      ),
                    ),
                    MusubiButton(
                      label: 'Reintentar',
                      kind: MusubiButtonKind.link,
                      expand: false,
                      onPressed: () => ref.invalidate(sellCategoriesProvider),
                    ),
                  ],
                ),
                _ => const SizedBox(
                  height: MusubiSizes.minTouch,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: MusubiSpinner(),
                  ),
                ),
              },
              if (_categoryError case final error?)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: FieldMessage(text: error),
                ),
            ],
          ),
        ),
        if (matches.isNotEmpty)
          NeedNotice(
            text: matches.length == 1
                ? 'Ya hay 1 publicación parecida. Te la mostramos al publicar.'
                : 'Ya hay ${matches.length} publicaciones parecidas. Te las '
                      'mostramos al publicar.',
          ),
      ],
    );
  }
}
