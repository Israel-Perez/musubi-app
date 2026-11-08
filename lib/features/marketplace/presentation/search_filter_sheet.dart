import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_controls.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_panel.dart';
import 'package:musubi_app/core/widgets/musubi_text_field.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/search_providers.dart';

/// Abre `Busqueda-filtros` (HU-10): categoria, rango de precio, estado y
/// "Ocultar agotados"; se aplica al tocar "Ver N resultados".
Future<void> showSearchFilterSheet(BuildContext context) =>
    showMusubiPanel<void>(context, builder: (_) => const SearchFilterSheet());

class SearchFilterSheet extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends ConsumerState<SearchFilterSheet> {
  /// Tope de la maqueta y de la API: $999,999.
  static const _maxPesos = 999999;

  late final TextEditingController _min;
  late final TextEditingController _max;
  String? _category;
  String? _condition;
  bool _hideSoldOut = false;
  String? _rangeError;

  @override
  void initState() {
    super.initState();
    final filter =
        ref.read(searchControllerProvider).value?.filter ??
        const CatalogFilter();
    _category = filter.category;
    _condition = filter.condition;
    _hideSoldOut = filter.hideSoldOut;
    _min = TextEditingController(text: _pesos(filter.minPriceCents));
    _max = TextEditingController(text: _pesos(filter.maxPriceCents));
  }

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  static String _pesos(int? cents) => cents == null ? '' : '${cents ~/ 100}';

  static int? _cents(String text) => switch (int.tryParse(text)) {
    final pesos? => pesos * 100,
    null => null,
  };

  /// Error del rango; `null` si se puede consultar y aplicar.
  String? get _rangeErrorFor {
    final min = int.tryParse(_min.text);
    final max = int.tryParse(_max.text);
    if ((min != null && min > _maxPesos) || (max != null && max > _maxPesos)) {
      return r'El precio no puede pasar de $999,999.';
    }
    if (min != null && max != null && min > max) {
      return 'El mínimo no puede ser mayor que el máximo.';
    }
    return null;
  }

  bool _validate() {
    final error = _rangeErrorFor;
    setState(() => _rangeError = error);
    return error == null;
  }

  CatalogFilter get _draft => CatalogFilter(
    category: _category,
    minPriceCents: _cents(_min.text),
    maxPriceCents: _cents(_max.text),
    condition: _condition,
    hideSoldOut: _hideSoldOut,
  );

  void _apply() {
    if (!_validate()) return;
    unawaited(ref.read(searchControllerProvider.notifier).applyFilter(_draft));
    Navigator.of(context).pop();
  }

  void _clear() => setState(() {
    _category = null;
    _condition = null;
    _hideSoldOut = false;
    _rangeError = null;
    _min.clear();
    _max.clear();
  });

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final query = ref.watch(searchControllerProvider).value?.query ?? '';
    // Un rango invalido no se manda a la API ni al preview.
    final valid = _rangeErrorFor == null;
    final preview = valid
        ? ref
              .watch(
                searchFilterPreviewProvider((query: query, filter: _draft)),
              )
              .value
        : null;
    final cta = switch (preview) {
      null => 'Ver resultados',
      1 => 'Ver 1 resultado',
      final n => 'Ver $n resultados',
    };
    final categories = ref.watch(searchCategoriesProvider);

    return MusubiPanel(
      key: const Key('search-filter-sheet'),
      title: 'Filtros',
      actions: [
        Row(
          spacing: 10,
          children: [
            Pressable(
              onTap: _clear,
              semanticLabel: 'Limpiar',
              builder: (context, pressed) => Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: pressed ? c.surfacePressed : null,
                  borderRadius: BorderRadius.circular(MusubiSizes.radiusButton),
                ),
                child: Text(
                  'Limpiar',
                  style: MusubiType.style(
                    15,
                    weight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
              ),
            ),
            Expanded(
              child: MusubiButton(label: cta, onPressed: _apply),
            ),
          ],
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 22,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              const _SectionLabel('Categoría'),
              switch (categories) {
                AsyncData(:final value) => Wrap(
                  spacing: 8,
                  children: [
                    _CategoryChip(
                      label: 'Todo',
                      selected: _category == null,
                      onTap: () => setState(() => _category = null),
                    ),
                    for (final category in value)
                      _CategoryChip(
                        label: category.name,
                        selected: _category == category.slug,
                        onTap: () => setState(() => _category = category.slug),
                      ),
                  ],
                ),
                AsyncError() => Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: Text(
                        'No pudimos cargar las categorías.',
                        style: MusubiType.style(13.5, color: c.textSecondary),
                      ),
                    ),
                    Pressable(
                      onTap: () => ref.invalidate(searchCategoriesProvider),
                      semanticLabel: 'Reintentar',
                      builder: (context, _) => Container(
                        height: MusubiSizes.minTouch,
                        alignment: Alignment.center,
                        child: Text(
                          'Reintentar',
                          style: MusubiType.style(
                            14,
                            weight: FontWeight.w700,
                            color: c.brand,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                _ => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 11),
                  child: Center(
                    child: SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                ),
              },
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 10,
            children: [
              const _SectionLabel('Rango de precio'),
              Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: MusubiTextField(
                      label: 'Mínimo',
                      fieldKey: const Key('filter-min'),
                      controller: _min,
                      hint: '0',
                      prefixText: r'$',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(7),
                      ],
                      onChanged: (_) => setState(() {}),
                      sheet: true,
                    ),
                  ),
                  Expanded(
                    child: MusubiTextField(
                      label: 'Máximo',
                      fieldKey: const Key('filter-max'),
                      controller: _max,
                      hint: '0',
                      prefixText: r'$',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(7),
                      ],
                      onChanged: (_) => setState(() {}),
                      sheet: true,
                    ),
                  ),
                ],
              ),
              if (_rangeError != null) FieldMessage(text: _rangeError!),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 10,
            children: [
              const _SectionLabel('Estado'),
              _ConditionSegments(
                key: const Key('search-condition'),
                selected: _condition,
                onSelect: (value) => setState(() => _condition = value),
              ),
            ],
          ),
          Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.only(left: 14, right: 4),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(MusubiSizes.radiusButton),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Ocultar agotados',
                    style: MusubiType.style(
                      14.5,
                      weight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                ),
                MusubiSwitch(
                  value: _hideSoldOut,
                  semanticLabel: 'Ocultar agotados',
                  width: 50,
                  height: 30,
                  knob: 24,
                  onChanged: (value) => setState(() => _hideSoldOut = value),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: MusubiType.style(
      14,
      weight: FontWeight.w800,
      color: context.musubi.textPrimary,
    ),
  );
}

/// Pastilla de categoria: fondo, borde y palomita al estar elegida.
class _CategoryChip extends StatelessWidget {
  const new({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      selected: selected,
      builder: (context, _) => SizedBox(
        height: MusubiSizes.minTouch,
        child: Center(
          child: Container(
            height: 38,
            padding: EdgeInsets.only(left: selected ? 12 : 14, right: 14),
            decoration: BoxDecoration(
              color: selected ? c.brandSoft : null,
              borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
              border: Border.all(
                color: selected ? c.brandBorder : c.border,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: [
                if (selected)
                  MusubiIcon(
                    MusubiIcons.check,
                    size: 15,
                    strokeWidth: 2.6,
                    color: c.brand,
                  ),
                Text(
                  label,
                  style: MusubiType.style(
                    14,
                    weight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? c.brand : c.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Todos / Nuevo / Usado (control segmentado de la maqueta). `null` es Todos.
class _ConditionSegments extends StatelessWidget {
  const new({required this.selected, required this.onSelect, super.key});

  final String? selected;
  final ValueChanged<String?> onSelect;

  static const _options = <(String?, String)>[
    (null, 'Todos'),
    ('new', 'Nuevo'),
    ('used', 'Usado'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Container(
      height: MusubiSizes.minTouch + 6,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(MusubiSizes.radiusField),
      ),
      child: Row(
        spacing: 3,
        children: [
          for (final (value, label) in _options)
            Expanded(
              child: Pressable(
                onTap: () => onSelect(value),
                selected: value == selected,
                semanticLabel: label,
                builder: (context, _) {
                  final on = value == selected;
                  return Container(
                    decoration: on
                        ? BoxDecoration(
                            color: c.elevated,
                            borderRadius: BorderRadius.circular(11),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1F1C1C1E),
                                offset: Offset(0, 1),
                                blurRadius: 3,
                              ),
                            ],
                          )
                        : null,
                    alignment: Alignment.center,
                    child: Text(
                      label,
                      style: MusubiType.style(
                        14,
                        weight: on ? FontWeight.w800 : FontWeight.w600,
                        color: on ? c.textPrimary : c.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
