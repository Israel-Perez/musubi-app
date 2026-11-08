import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/feedback_views.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_panel.dart';
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/features/auth/presentation/account_gate.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/domain/search_filter.dart';
import 'package:musubi_app/features/marketplace/domain/search_sort.dart';
import 'package:musubi_app/features/marketplace/presentation/campus_chip.dart';
import 'package:musubi_app/features/marketplace/presentation/home_cards.dart';
import 'package:musubi_app/features/marketplace/presentation/search_filter_sheet.dart';
import 'package:musubi_app/features/marketplace/presentation/search_providers.dart';

/// `Busqueda` y `Busqueda-vacia` (HU-09): busca por palabra clave en el
/// catalogo del campus y abre el detalle de cada resultado (HU-11).
///
/// NOTE (HU-10): el boton y la hoja de filtros de la busqueda.
/// NOTE (HU-12): guardar la busqueda y avisar en el estado vacio.
class SearchScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  /// Pausa antes de buscar mientras se escribe; una tecla mas la reinicia.
  static const _debounceDelay = Duration(milliseconds: 300);

  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // HU-10: al entrar se listan todas las publicaciones.
      unawaited(ref.read(searchControllerProvider.notifier).search(''));
      // HU-10: desde el boton de filtros de Inicio se abre la hoja directo.
      final openFilters =
          GoRouter.maybeOf(context)?.state.uri.queryParameters['filtros'] ==
          '1';
      if (openFilters) {
        unawaited(_openFilters());
      } else {
        _focus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      unawaited(ref.read(searchControllerProvider.notifier).clear());
      return;
    }
    _debounce = Timer(_debounceDelay, () => _submit(value));
  }

  void _submit(String value) {
    _debounce?.cancel();
    final filter =
        ref.read(searchControllerProvider).value?.filter ??
        const SearchFilter();
    unawaited(
      ref.read(searchControllerProvider.notifier).search(value, filter: filter),
    );
  }

  Future<void> _openFilters() async {
    final initial =
        ref.read(searchControllerProvider).value?.filter ??
        const SearchFilter();
    final chosen = await showSearchFilterSheet(context, initial: initial);
    if (!mounted || chosen == null) return;
    await ref.read(searchControllerProvider.notifier).applyFilter(chosen);
  }

  Future<void> _pickSort() async {
    final current =
        ref.read(searchControllerProvider).value?.sort ?? SearchSort.relevant;
    final picked = await showMusubiPanel<SearchSort>(
      context,
      builder: (context) => MusubiPanel(
        key: const Key('search-sort-sheet'),
        title: 'Ordenar por',
        bodyInset: 12,
        child: MusubiOptions<SearchSort>(
          selected: current,
          options: [
            for (final option in SearchSort.values)
              MusubiOption(value: option, label: option.label),
          ],
          onPick: (option) => Navigator.of(context).pop(option),
        ),
      ),
    );
    if (!mounted || picked == null) return;
    await ref.read(searchControllerProvider.notifier).setSort(picked);
  }

  void _searchFor(String query) {
    _controller.text = query;
    _controller.selection = TextSelection.collapsed(offset: query.length);
    _submit(query);
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    unawaited(ref.read(searchControllerProvider.notifier).clear());
    _focus.requestFocus();
  }

  Future<void> _goToPage(int page) async {
    try {
      await ref.read(searchControllerProvider.notifier).goToPage(page);
    } on Object catch (error) {
      if (!mounted) return;
      showMusubiSnack(
        ScaffoldMessenger.of(context),
        error is ApiFailure
            ? error.message
            : 'No pudimos cargar la página. Inténtalo de nuevo.',
        icon: MusubiIcons.circleAlert,
        tone: SnackTone.warn,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final session = ref.watch(sessionControllerProvider);
    final signedIn = session is SignedIn;
    final results = ref.watch(searchControllerProvider);
    final filter = results.value?.filter ?? const SearchFilter();
    final now = ref.watch(clockProvider)().toLocal();

    void open(ProductSummary product) =>
        unawaited(context.push(AppRoutes.product(product.id), extra: product));

    // NOTE (HU-53): guardar un producto desde la busqueda (favoritos); el
    // historial de busquedas no existe por RNF-07.
    void save() {
      if (signedIn) return;
      unawaited(
        showAccountGate(
          context,
          motive: AccountGateMotive.save,
          returnTo: AppRoutes.search,
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 10, 16, 0),
              child: Row(
                children: [
                  Pressable(
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppRoutes.home);
                      }
                    },
                    semanticLabel: 'Regresar',
                    builder: (context, pressed) => SizedBox.square(
                      dimension: MusubiSizes.minTouch,
                      child: Center(
                        child: MusubiIcon(
                          MusubiIcons.chevronLeft,
                          strokeWidth: 1.9,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SearchField(
                      controller: _controller,
                      focusNode: _focus,
                      onChanged: _onChanged,
                      onSubmitted: _submit,
                      onClear: _clear,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _SearchFilterButton(count: filter.count, onTap: _openFilters),
                ],
              ),
            ),
            _HistoryRow(onPick: _searchFor),
            Expanded(
              child: switch (results) {
                AsyncData(:final value) when value.empty => _EmptyResults(
                  query: value.query,
                  filters: !value.filter.isEmpty,
                ),
                AsyncData(:final value) => _Results(
                  state: value,
                  now: now,
                  onOpen: open,
                  onSave: save,
                  onPage: _goToPage,
                  onSort: _pickSort,
                ),
                AsyncError(:final error) => _SearchError(
                  failure: error is ApiFailure ? error : null,
                  onRetry: () => _submit(_controller.text),
                ),
                _ => Center(
                  child: Semantics(
                    label: 'Buscando productos',
                    child: CircularProgressIndicator(color: c.brand),
                  ),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Campo compacto de la maqueta: 48 de alto, fondo superficie y radio 14.
class _SearchField extends StatelessWidget {
  const new({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Container(
      height: 48,
      padding: const EdgeInsets.only(left: 12, right: 2),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(MusubiSizes.radiusField),
      ),
      child: Row(
        children: [
          MusubiIcon(MusubiIcons.search, size: 19, color: c.textPrimary),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              key: const Key('search-input'),
              controller: controller,
              focusNode: focusNode,
              textInputAction: TextInputAction.search,
              maxLength: 80,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              cursorColor: c.brand,
              style: MusubiType.style(
                16,
                weight: FontWeight.w600,
                color: c.textPrimary,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                counterText: '',
                hintText: 'Busca en tu campus',
                hintStyle: MusubiType.style(
                  16,
                  weight: FontWeight.w600,
                  color: c.placeholder,
                ),
              ),
            ),
          ),
          ValueListenableBuilder(
            valueListenable: controller,
            builder: (context, value, _) => value.text.isEmpty
                ? const SizedBox.shrink()
                : Pressable(
                    onTap: onClear,
                    semanticLabel: 'Borrar búsqueda',
                    builder: (context, pressed) => SizedBox.square(
                      dimension: MusubiSizes.minTouch,
                      child: Center(
                        child: MusubiIcon(
                          MusubiIcons.x,
                          size: 18,
                          color: c.textSecondary,
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

class _Results extends StatelessWidget {
  const new({
    required this.state,
    required this.now,
    required this.onOpen,
    required this.onSave,
    required this.onPage,
    required this.onSort,
  });

  final SearchState state;
  final DateTime now;
  final ValueChanged<ProductSummary> onOpen;
  final VoidCallback onSave;
  final ValueChanged<int> onPage;
  final VoidCallback onSort;

  @override
  Widget build(BuildContext context) {
    final count = state.total == 0 ? state.items.length : state.total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  spacing: 6,
                  children: [
                    Flexible(
                      child: Text(
                        count == 1 ? '1 resultado en' : '$count resultados en',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MusubiType.style(
                          13,
                          weight: FontWeight.w600,
                          color: context.musubi.textSecondary,
                        ),
                      ),
                    ),
                    const _CampusPill(),
                  ],
                ),
              ),
              _SortButton(label: state.sort.label, onTap: onSort),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 20,
              crossAxisSpacing: 12,
              mainAxisExtent: 240,
            ),
            itemCount: state.items.length,
            itemBuilder: (context, index) {
              final product = state.items[index];
              return RecentTile(
                product: product,
                now: now,
                onSave: onSave,
                onTap: () => onOpen(product),
              );
            },
          ),
        ),
        if (state.pageCount > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: _Pagination(
              page: state.page,
              pageCount: state.pageCount,
              onPage: onPage,
            ),
          ),
      ],
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const new({required this.query, required this.filters});

  final String query;
  final bool filters;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 44, 28, 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: c.surface,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: MusubiIcon(
                  MusubiIcons.search,
                  size: 30,
                  strokeWidth: 1.8,
                  color: c.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              switch (query) {
                _ when query.isNotEmpty => 'Sin resultados para «$query»',
                _ when filters => 'Sin resultados con estos filtros',
                _ => 'Aún no hay publicaciones',
              },
              textAlign: TextAlign.center,
              style: MusubiType.style(
                18,
                weight: FontWeight.w800,
                line: 24,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              switch (query) {
                _ when query.isNotEmpty =>
                  'Prueba con otras palabras o publica lo que necesitas.',
                _ when filters => 'Prueba con otros filtros.',
                _ => 'Publica lo que quieres vender para verlo aquí.',
              },
              textAlign: TextAlign.center,
              style: MusubiType.style(14, line: 20, color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchError extends StatelessWidget {
  const new({required this.failure, required this.onRetry});

  final ApiFailure? failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InlineMessage(
              title: 'No pudimos buscar',
              message:
                  failure?.message ??
                  'Revisa tu conexión e inténtalo de nuevo.',
              kind: InlineMessageKind.warning,
            ),
            const SizedBox(height: MusubiSizes.space4),
            MusubiButton(
              label: 'Reintentar',
              kind: MusubiButtonKind.secondary,
              height: MusubiSizes.buttonHeightSmall,
              expand: false,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

/// Paginacion por numero de pagina, debajo de los resultados.
class _Pagination extends StatelessWidget {
  const new({
    required this.page,
    required this.pageCount,
    required this.onPage,
  });

  final int page;
  final int pageCount;
  final ValueChanged<int> onPage;

  /// Numeros visibles; `null` es el separador de paginas lejanas.
  List<int?> get _slots {
    if (pageCount <= 5) return [for (var i = 1; i <= pageCount; i++) i];
    final start = (page - 2).clamp(1, pageCount - 4);
    return [
      if (start > 1) 1,
      if (start > 2) null,
      for (var i = start; i < start + 5; i++) i,
      if (start + 4 < pageCount - 1) null,
      if (start + 4 < pageCount) pageCount,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PageArrow(
          icon: MusubiIcons.chevronLeft,
          label: 'Página anterior',
          enabled: page > 1,
          onTap: () => onPage(page - 1),
        ),
        for (final slot in _slots)
          if (slot == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '…',
                style: MusubiType.style(14, color: c.textSecondary),
              ),
            )
          else
            Pressable(
              key: Key('page-$slot'),
              onTap: slot == page ? null : () => onPage(slot),
              semanticLabel: 'Página $slot',
              selected: slot == page,
              builder: (context, pressed) => Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: slot == page
                      ? c.brand
                      : pressed
                      ? c.surfacePressed
                      : null,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$slot',
                  style: MusubiType.style(
                    14,
                    weight: slot == page ? FontWeight.w800 : FontWeight.w700,
                    color: slot == page
                        ? const Color(0xFFFFFFFF)
                        : c.textPrimary,
                  ),
                ),
              ),
            ),
        _PageArrow(
          icon: MusubiIcons.chevronRight,
          label: 'Página siguiente',
          enabled: page < pageCount,
          onTap: () => onPage(page + 1),
        ),
      ],
    );
  }
}

class _PageArrow extends StatelessWidget {
  const new({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final MusubiIconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Pressable(
      onTap: enabled ? onTap : null,
      semanticLabel: label,
      builder: (context, pressed) => SizedBox.square(
        dimension: MusubiSizes.minTouch,
        child: Center(
          child: MusubiIcon(
            icon,
            size: 18,
            strokeWidth: 2.2,
            color: enabled
                ? (pressed ? c.brandText : c.textPrimary)
                : c.placeholder,
          ),
        ),
      ),
    );
  }
}

/// Pildora del campus de la maqueta: icono de birrete en circulo rojo + UTTT.
class _CampusPill extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Container(
      height: 26,
      padding: const EdgeInsets.only(left: 3, right: 9),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 5,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(color: c.brand, shape: BoxShape.circle),
            child: const Center(
              child: MusubiIcon(
                MusubiIcons.graduationCap,
                size: 12,
                strokeWidth: 2.4,
                color: Color(0xFFFFFFFF),
              ),
            ),
          ),
          Text(
            DefaultCampus.shortName,
            style: MusubiType.style(
              12.5,
              weight: FontWeight.w800,
              color: c.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Más relevantes ⌄" de la maqueta: abre los ordenes de la busqueda.
class _SortButton extends StatelessWidget {
  const new({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Pressable(
      key: const Key('search-sort'),
      onTap: onTap,
      semanticLabel: 'Ordenar por $label',
      builder: (context, pressed) => Container(
        height: MusubiSizes.minTouch,
        padding: const EdgeInsets.only(left: 8, right: 4),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            Text(
              label,
              style: MusubiType.style(
                13.5,
                weight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            MusubiIcon(
              MusubiIcons.chevronDown,
              size: 16,
              strokeWidth: 2.2,
              color: c.textPrimary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Busquedas recientes de la sesion: chips tocables y "Limpiar" a la derecha.
class _HistoryRow extends ConsumerWidget {
  const new({required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.musubi;
    final history = ref.watch(searchHistoryProvider);
    if (history.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 6, 8, 6),
              itemCount: history.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final query = history[index];
                return Pressable(
                  onTap: () => onPick(query),
                  semanticLabel: 'Buscar $query',
                  builder: (context, pressed) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: pressed ? c.surfacePressed : c.surface,
                      borderRadius: BorderRadius.circular(
                        MusubiSizes.radiusChip,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 6,
                      children: [
                        MusubiIcon(
                          MusubiIcons.clock,
                          size: 14,
                          color: c.textSecondary,
                        ),
                        Text(
                          query,
                          style: MusubiType.style(
                            13,
                            weight: FontWeight.w600,
                            color: c.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Pressable(
            key: const Key('clear-history'),
            onTap: ref.read(searchHistoryProvider.notifier).clear,
            semanticLabel: 'Limpiar historial',
            builder: (context, pressed) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'Limpiar',
                style: MusubiType.style(
                  13,
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

/// Boton de filtros de `Busqueda` (48 x 48) con el globo de activos.
class _SearchFilterButton extends StatelessWidget {
  const new({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final active = count > 0;
    return Pressable(
      key: const Key('search-filter'),
      onTap: onTap,
      semanticLabel: switch (count) {
        0 => 'Filtrar',
        1 => 'Filtrar, 1 filtro activo',
        _ => 'Filtrar, $count filtros activos',
      },
      builder: (context, pressed) => SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: pressed
                      ? c.surfacePressed
                      : active
                      ? c.brandSoft
                      : c.surface,
                  borderRadius: BorderRadius.circular(MusubiSizes.radiusField),
                ),
                child: Center(
                  child: MusubiIcon(
                    MusubiIcons.slidersHorizontal,
                    size: 20,
                    color: active ? c.brandStrongText : c.textPrimary,
                  ),
                ),
              ),
            ),
            if (active)
              Positioned(
                top: -5,
                right: -5,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 20),
                  height: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: c.brand,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: c.background, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$count',
                    style: MusubiType.style(
                      10.5,
                      weight: FontWeight.w800,
                      color: const Color(0xFFFFFFFF),
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
