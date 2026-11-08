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
import 'package:musubi_app/features/marketplace/domain/search_filter.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';
import 'package:musubi_app/features/marketplace/presentation/search_providers.dart';

/// Abre `Busqueda-filtros` (HU-10) con los filtros aplicados y devuelve el
/// borrador si la persona toca "Ver N resultados".
Future<SearchFilter?> showSearchFilterSheet(
  BuildContext context, {
  required SearchFilter initial,
}) => showMusubiPanel<SearchFilter>(
  context,
  builder: (_) => SearchFilterSheet(initial: initial),
);

/// Tope del control deslizante: $2,000 o mas (sin limite superior).
const _maxPricePesos = 2000;

/// Hoja de filtros de la busqueda: categoria, rango de precio y estado.
///
/// NOTE (HU-10): el orden "Mas relevantes" de la maqueta no se muestra; la API
/// ordena por fecha. "Ocultar agotados" no aplica con `q` (HU-09).
class SearchFilterSheet extends ConsumerStatefulWidget {
  const new({required this.initial, super.key});

  final SearchFilter initial;

  @override
  ConsumerState<SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends ConsumerState<SearchFilterSheet> {
  static const _debounce = Duration(milliseconds: 300);

  late SearchFilter _draft = widget.initial;
  late final _min = TextEditingController(
    text: widget.initial.minCents == null
        ? ''
        : '${widget.initial.minCents! ~/ 100}',
  );
  late final _max = TextEditingController(
    text: widget.initial.maxCents == null
        ? ''
        : '${widget.initial.maxCents! ~/ 100}',
  );
  Timer? _priceTimer;
  String? _priceError;
  int _shake = 0;

  @override
  void dispose() {
    _priceTimer?.cancel();
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  int? _pesos(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : int.tryParse(text);
  }

  int? _cents(TextEditingController controller) {
    final pesos = _pesos(controller);
    return pesos == null ? null : pesos * 100;
  }

  /// Posiciones del control deslizante; si el texto no cuadra, se ordenan.
  RangeValues get _range {
    double value(TextEditingController controller) =>
        (_pesos(controller) ?? (controller == _min ? 0 : _maxPricePesos))
            .clamp(0, _maxPricePesos)
            .toDouble();
    final start = value(_min);
    final end = value(_max);
    return start <= end ? RangeValues(start, end) : RangeValues(end, start);
  }

  SearchFilter get _current => SearchFilter(
    category: _draft.category,
    minCents: _cents(_min),
    maxCents: _cents(_max),
    condition: _draft.condition,
    hideSoldOut: _draft.hideSoldOut,
  );

  String? _validate(SearchFilter filter) {
    final min = filter.minCents;
    final max = filter.maxCents;
    return min != null && max != null && min > max
        ? 'El máximo debe ser mayor o igual que el mínimo.'
        : null;
  }

  void _onPriceChanged() {
    _priceTimer?.cancel();
    final next = _current;
    final error = _validate(next);
    setState(() => _priceError = error);
    if (error != null) return;
    _priceTimer = Timer(_debounce, () {
      if (!mounted) return;
      setState(
        () => _draft = SearchFilter(
          category: _draft.category,
          minCents: next.minCents,
          maxCents: next.maxCents,
          condition: _draft.condition,
          hideSoldOut: _draft.hideSoldOut,
        ),
      );
    });
  }

  /// El control deslizante escribe el precio en los campos y refresca la
  /// vista previa (mismo retardo de 300 ms).
  void _onRangeChanged(RangeValues values) {
    final start = values.start.round();
    final end = values.end.round();
    _min.text = start == 0 ? '' : '$start';
    _max.text = end == _maxPricePesos ? '' : '$end';
    _onPriceChanged();
  }

  void _selectCategory(String slug) {
    _priceTimer?.cancel();
    setState(
      () => _draft = SearchFilter(
        category: _draft.category == slug ? null : slug,
        minCents: _cents(_min),
        maxCents: _cents(_max),
        condition: _draft.condition,
        hideSoldOut: _draft.hideSoldOut,
      ),
    );
  }

  void _selectCondition(ProductConditionFilter condition) {
    _priceTimer?.cancel();
    setState(
      () => _draft = SearchFilter(
        category: _draft.category,
        minCents: _cents(_min),
        maxCents: _cents(_max),
        condition: condition,
        hideSoldOut: _draft.hideSoldOut,
      ),
    );
  }

  void _toggleSoldOut(bool hide) {
    _priceTimer?.cancel();
    setState(
      () => _draft = SearchFilter(
        category: _draft.category,
        minCents: _cents(_min),
        maxCents: _cents(_max),
        condition: _draft.condition,
        hideSoldOut: hide,
      ),
    );
  }

  void _clear() {
    _priceTimer?.cancel();
    _min.clear();
    _max.clear();
    setState(() {
      _draft = const SearchFilter();
      _priceError = null;
    });
    _toast('Filtros borrados');
  }

  /// Aviso flotante sobre la hoja (la del `ScaffoldMessenger` queda debajo).
  void _toast(String message) {
    final c = context.musubi;
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: 24,
        right: 24,
        bottom: 120,
        child: IgnorePointer(
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.textPrimary,
                borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Text(
                  message,
                  style: MusubiType.style(
                    14,
                    weight: FontWeight.w700,
                    color: c.background,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(entry);
    Timer(const Duration(seconds: 2), () {
      if (entry.mounted) entry.remove();
    });
  }

  void _apply() {
    final filter = _current;
    final error = _validate(filter);
    if (error != null) {
      setState(() {
        _priceError = error;
        _shake++;
      });
      return;
    }
    Navigator.of(context).pop(filter);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final categories = ref.watch(categoriesProvider);
    final query = ref.watch(searchControllerProvider).value?.query ?? '';
    final preview = ref
        .watch(searchPreviewProvider((query: query, filter: _draft)))
        .value;
    final cta = query.isEmpty && _draft.isEmpty
        ? 'Ver resultados'
        : _priceError != null || preview == null
        ? 'Ver resultados'
        : preview == 1
        ? 'Ver 1 resultado'
        : 'Ver $preview resultados';

    return MusubiPanel(
      key: const Key('search-filter-sheet'),
      title: 'Filtros',
      tall: true,
      actions: [
        Row(
          spacing: 10,
          children: [
            MusubiButton(
              label: 'Limpiar',
              kind: MusubiButtonKind.secondary,
              height: MusubiSizes.buttonHeightSheet,
              expand: false,
              onPressed: _clear,
            ),
            Expanded(
              child: MusubiButton(
                label: cta,
                height: MusubiSizes.buttonHeightSheet,
                onPressed: _apply,
              ),
            ),
          ],
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Legend('Categoría'),
          const SizedBox(height: 8),
          categories.when(
            data: (items) => Wrap(
              spacing: 8,
              children: [
                for (final category in items)
                  _CategoryChip(
                    label: category.name,
                    selected: _draft.category == category.slug,
                    onTap: () => _selectCategory(category.slug),
                  ),
              ],
            ),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: LinearProgressIndicator(minHeight: 2),
            ),
            error: (_, _) => Row(
              children: [
                Expanded(
                  child: Text(
                    'No pudimos cargar las categorías.',
                    style: MusubiType.style(14, color: c.textSecondary),
                  ),
                ),
                Pressable(
                  onTap: () => ref.invalidate(categoriesProvider),
                  semanticLabel: 'Reintentar categorías',
                  builder: (context, _) => Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'Reintentar',
                      style: MusubiType.style(
                        14,
                        weight: FontWeight.w700,
                        color: c.brandText,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const _Legend('Rango de precio'),
          const SizedBox(height: 8),
          _PriceHistogram(
            from: _range.start,
            to: _pesos(_max) == null ? double.infinity : _range.end,
          ),
          const SizedBox(height: 2),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              activeTrackColor: c.brand,
              inactiveTrackColor: c.border,
              overlayColor: c.brandSoft,
              rangeThumbShape: _ThumbShape(fill: c.background, border: c.brand),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
              showValueIndicator: ShowValueIndicator.never,
            ),
            child: RangeSlider(
              key: const Key('filter-price-slider'),
              values: _range,
              max: _maxPricePesos.toDouble(),
              onChanged: _onRangeChanged,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            spacing: 12,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: MusubiTextField(
                  label: 'Mínimo',
                  hint: '300',
                  prefixText: r'$',
                  controller: _min,
                  fieldKey: const Key('filter-min'),
                  sheet: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  onChanged: (_) => _onPriceChanged(),
                ),
              ),
              Expanded(
                child: MusubiTextField(
                  label: 'Máximo',
                  hint: '700',
                  prefixText: r'$',
                  controller: _max,
                  fieldKey: const Key('filter-max'),
                  sheet: true,
                  errorText: _priceError,
                  shakeTrigger: _shake,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  onChanged: (_) => _onPriceChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const _Legend('Estado'),
          const SizedBox(height: 10),
          _ConditionSegment(
            value: _draft.condition,
            onChanged: _selectCondition,
          ),
          const SizedBox(height: 16),
          Container(
            height: 52,
            padding: const EdgeInsets.fromLTRB(14, 0, 4, 0),
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
                  value: _draft.hideSoldOut,
                  onChanged: _toggleSoldOut,
                  semanticLabel: 'Ocultar agotados',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
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
      builder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Container(
          height: 38,
          padding: EdgeInsets.only(left: selected ? 12 : 14, right: 14),
          decoration: BoxDecoration(
            color: selected ? c.brandSoft : null,
            borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
            border: Border.all(
              color: selected ? c.brandSoftBorder : c.border,
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
                  color: c.brandStrongText,
                ),
              Text(
                label,
                style: MusubiType.style(
                  14,
                  weight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? c.brandStrongText : c.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConditionSegment extends StatelessWidget {
  const new({required this.value, required this.onChanged});

  final ProductConditionFilter value;
  final ValueChanged<ProductConditionFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(MusubiSizes.radiusButton),
      ),
      child: Row(
        spacing: 3,
        children: [
          for (final option in ProductConditionFilter.values)
            Expanded(
              child: Pressable(
                onTap: () => onChanged(option),
                semanticLabel: option.label,
                selected: option == value,
                builder: (context, _) => Container(
                  decoration: BoxDecoration(
                    color: option == value ? c.background : null,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: option == value
                        ? const [
                            BoxShadow(
                              color: Color(0x1F1C1C1E),
                              offset: Offset(0, 1),
                              blurRadius: 3,
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    option.label,
                    style: MusubiType.style(
                      14,
                      weight: option == value
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: option == value ? c.textPrimary : c.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Histograma decorativo de la maqueta (`aria-hidden`): no representa los
/// datos de la consulta.
class _PriceHistogram extends StatelessWidget {
  const new({required this.from, required this.to});

  /// Rango elegido en pesos; las barras dentro cambian de color.
  final double from;
  final double to;

  static const _heights = [
    8.0,
    14.0,
    20.0,
    30.0,
    36.0,
    26.0,
    18.0,
    12.0,
    8.0,
    6.0,
    4.0,
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final step = _maxPricePesos / _heights.length;
    return ExcludeSemantics(
      child: SizedBox(
        height: 36,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final (index, height) in _heights.indexed)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: height,
                      decoration: BoxDecoration(
                        color: index * step < to && (index + 1) * step > from
                            ? c.brandSoftBorder
                            : c.border,
                        borderRadius: BorderRadius.circular(3),
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

/// Pulgar de la maqueta: circulo blanco de 26 con borde rojo de 2.
class _ThumbShape extends RangeSliderThumbShape {
  const new({required this.fill, required this.border});

  final Color fill;
  final Color border;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(26, 26);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required SliderThemeData sliderTheme,
    bool isDiscrete = false,
    bool isEnabled = true,
    bool isOnTop = true,
    TextDirection textDirection = TextDirection.ltr,
    Thumb thumb = Thumb.start,
    bool isPressed = false,
  }) {
    context.canvas
      ..drawCircle(
        center.translate(0, 1),
        13,
        Paint()
          ..color = const Color(0x331C1C1E)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      )
      ..drawCircle(center, 13, Paint()..color = fill)
      ..drawCircle(
        center,
        12,
        Paint()
          ..color = border
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
  }
}
