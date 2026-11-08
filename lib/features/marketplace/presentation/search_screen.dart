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
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/features/auth/presentation/account_gate.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/domain/search_filter.dart';
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
      if (mounted) _focus.requestFocus();
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

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    unawaited(ref.read(searchControllerProvider.notifier).clear());
    _focus.requestFocus();
  }

  Future<void> _loadMore() async {
    try {
      await ref.read(searchControllerProvider.notifier).loadMore();
    } on Object catch (error) {
      if (!mounted) return;
      showMusubiSnack(
        ScaffoldMessenger.of(context),
        error is ApiFailure
            ? error.message
            : 'No pudimos cargar más resultados. Inténtalo de nuevo.',
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
            Expanded(
              child: switch (results) {
                AsyncData(:final value) when value.empty => _EmptyResults(
                  query: value.query,
                ),
                AsyncData(:final value) when !value.hasCriteria =>
                  const _Prompt(),
                AsyncData(:final value) => _Results(
                  state: value,
                  now: now,
                  onOpen: open,
                  onSave: save,
                  onLoadMore: _loadMore,
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
    required this.onLoadMore,
  });

  final SearchState state;
  final DateTime now;
  final ValueChanged<ProductSummary> onOpen;
  final VoidCallback onSave;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final count = state.total == 0 ? state.items.length : state.total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Text(
            count == 1
                ? '1 resultado en ${DefaultCampus.shortName}'
                : '$count resultados en ${DefaultCampus.shortName}',
            style: MusubiType.style(
              13,
              weight: FontWeight.w600,
              color: c.textSecondary,
            ),
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
        if (state.hasMore)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: MusubiButton(
              label: 'Cargar más',
              kind: MusubiButtonKind.secondary,
              height: MusubiSizes.buttonHeightSmall,
              loading: state.loadingMore,
              loadingLabel: 'Cargando…',
              onPressed: state.loadingMore ? null : onLoadMore,
            ),
          ),
      ],
    );
  }
}

class _Prompt extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 0, 40, 80),
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
            const SizedBox(height: 14),
            Text(
              'Busca lo que necesitas',
              textAlign: TextAlign.center,
              style: MusubiType.style(
                18,
                weight: FontWeight.w800,
                line: 24,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Escribe un producto, una marca o una palabra clave.',
              textAlign: TextAlign.center,
              style: MusubiType.style(14, line: 20, color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const new({required this.query});

  final String query;

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
              query.isEmpty
                  ? 'Sin resultados con estos filtros'
                  : 'Sin resultados para «$query»',
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
              query.isEmpty
                  ? 'Prueba con otros filtros.'
                  : 'Prueba con otras palabras o publica lo que necesitas.',
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
