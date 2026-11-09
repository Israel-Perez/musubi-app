import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/app/shell/musubi_bottom_bar.dart';
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
import 'package:musubi_app/core/widgets/skeleton.dart';
import 'package:musubi_app/features/auth/presentation/account_gate.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/campus_chip.dart';
import 'package:musubi_app/features/marketplace/presentation/home_cards.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';
import 'package:musubi_app/features/purchase_requests/domain/wanted_board.dart';
import 'package:musubi_app/features/purchase_requests/presentation/wanted_board_cards.dart';
import 'package:musubi_app/features/purchase_requests/presentation/wanted_board_providers.dart';
import 'package:musubi_app/features/purchase_requests/presentation/wanted_providers.dart';

/// Pestana "Se busca" (HU-15): con sesion, el tablero `Se-busca` con la lupa
/// y "Filtrar solicitudes"; sin sesion, `Se-busca-visitante` (HU-48), que
/// pide la cuenta para ofrecer o pedir algo.
class WantedBoardScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<WantedBoardScreen> createState() => _WantedBoardScreenState();
}

class _WantedBoardScreenState extends ConsumerState<WantedBoardScreen> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  bool _searching = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    if (_searching) {
      // Como la maqueta: cerrar la lupa borra lo escrito.
      _debounce?.cancel();
      _search.clear();
      ref.read(wantedBoardFilterProvider.notifier).search('');
      setState(() => _searching = false);
      return;
    }
    setState(() => _searching = true);
    _searchFocus.requestFocus();
  }

  void _onQuery(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => ref.read(wantedBoardFilterProvider.notifier).search(value),
    );
  }

  void _offer(bool signedIn) {
    if (!signedIn) {
      unawaited(
        showAccountGate(
          context,
          motive: AccountGateMotive.offer,
          returnTo: AppRoutes.wanted,
        ),
      );
      return;
    }
    // NOTE (HU-16): "Yo tengo este producto" abre `Yo-tengo-vincular` u
    // `Yo-tengo-oferta`.
    showMusubiSnack(
      ScaffoldMessenger.of(context),
      'Muy pronto podrás ofrecerlo desde aquí.',
      icon: MusubiIcons.hand,
    );
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.metrics.extentAfter < 600) {
      unawaited(ref.read(wantedBoardProvider.notifier).loadMore());
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final signedIn = ref.watch(
      sessionControllerProvider.select((s) => s is SignedIn),
    );
    final board = ref.watch(wantedBoardProvider);
    final filter = ref.watch(wantedBoardFilterProvider);
    final now = ref.watch(clockProvider)();
    // Se termina donde empieza la barra (sin la franja de "Publicar").
    final bottom = math
        .max(0, MediaQuery.paddingOf(context).bottom - MusubiBottomBar.overhang)
        .toDouble();

    final list = switch (board) {
      AsyncData(:final value) => _list(value, filter, now, signedIn),
      AsyncError(:final error) when board.value == null => [
        SliverToBoxAdapter(
          child: _BoardError(
            failure: error is ApiFailure ? error : null,
            onRetry: () => ref.invalidate(wantedBoardProvider),
          ),
        ),
      ],
      _ when board.value != null => _list(board.value!, filter, now, signedIn),
      _ => [SliverToBoxAdapter(child: _BoardLoading(member: signedIn))],
    };

    final slivers = signedIn
        ? [
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: _MemberHeader(
                  filters: filter.count,
                  searching: _searching,
                  onSearch: _toggleSearch,
                  onFilter: () => unawaited(_openFilters()),
                ),
              ),
            ),
            if (_searching)
              SliverToBoxAdapter(
                child: _SearchBox(
                  controller: _search,
                  focusNode: _searchFocus,
                  onChanged: _onQuery,
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverMainAxisGroup(slivers: list),
            ),
          ]
        : [
            const SliverToBoxAdapter(child: _VisitorHero()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Semantics(
                  header: true,
                  child: Text(
                    'Lo que se busca hoy',
                    style: MusubiType.style(
                      20,
                      weight: FontWeight.w800,
                      line: 26,
                      em: -0.02,
                      color: c.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: SliverMainAxisGroup(
                slivers: [
                  ...list,
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: _NeedSomethingCard(
                        onAsk: () => unawaited(
                          showAccountGate(
                            context,
                            motive: AccountGateMotive.request,
                            returnTo: AppRoutes.wanted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ];

    final scroll = NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: RefreshIndicator(
        color: c.brand,
        edgeOffset: signedIn ? 0 : MediaQuery.paddingOf(context).top,
        onRefresh: () => ref.refresh(wantedBoardProvider.future),
        child: CustomScrollView(
          key: const Key('wanted-board'),
          slivers: [
            ...slivers,
            SliverToBoxAdapter(child: SizedBox(height: bottom + 24)),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: c.background,
      body: signedIn
          ? scroll
          : AnnotatedRegion<SystemUiOverlayStyle>(
              // Sobre el rojo del encabezado, la barra de estado en blanco.
              value: SystemUiOverlayStyle.light,
              child: scroll,
            ),
    );
  }

  List<Widget> _list(
    WantedBoardState state,
    WantedBoardFilter filter,
    DateTime now,
    bool signedIn,
  ) {
    if (state.items.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: filter.narrowed
              ? const _NoMatches()
              : EmptyShelf(
                  key: const Key('wanted-board-empty'),
                  icon: MusubiIcons.megaphone,
                  title: 'Nadie ha pedido nada todavía',
                  message:
                      'Pide lo que necesitas y recibe ofertas de tu campus.',
                  actionLabel: 'Pedir algo',
                  tinted: true,
                  onAction: () => signedIn
                      ? unawaited(context.push(AppRoutes.need))
                      : unawaited(
                          showAccountGate(
                            context,
                            motive: AccountGateMotive.request,
                            returnTo: AppRoutes.wanted,
                          ),
                        ),
                ),
        ),
      ];
    }
    return [
      SliverList.separated(
        itemCount: state.items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, i) {
          final request = state.items[i];
          // `__rise` escalonado como la maqueta (.08 s entre boletos; el
          // visitante empieza en .1 s, despues de los pasos).
          return RiseIn(
            key: ValueKey('wanted-${request.id}'),
            duration: const Duration(milliseconds: 450),
            delay: Duration(
              milliseconds: math.min(i, 6) * 80 + (signedIn ? 0 : 100),
            ),
            child: signedIn
                ? WantedBoardCard(
                    request: request,
                    now: now,
                    onOffer: () => _offer(true),
                  )
                : WantedVisitorCard(
                    request: request,
                    now: now,
                    onOffer: () => _offer(false),
                  ),
          );
        },
      ),
      if (state.loadingMore)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 14),
            child: SkeletonShimmer(
              child: SkeletonBox(height: 220, radius: 22, brand: true),
            ),
          ),
        ),
    ];
  }

  /// "Filtrar solicitudes" (`UI.options` sin marca): Categoría, Presupuesto
  /// y Fecha límite, cada una con lo elegido debajo. Elegir una cierra la
  /// hoja y abre la suya 240 ms despues, como la maqueta.
  Future<void> _openFilters() async {
    final filter = ref.read(wantedBoardFilterProvider);
    final picked = await showMusubiPanel<String>(
      context,
      builder: (context) => MusubiPanel(
        key: const Key('wanted-filters'),
        title: 'Filtrar solicitudes',
        bodyInset: 12,
        child: MusubiOptions<String>(
          plain: true,
          options: [
            MusubiOption(
              value: 'category',
              label: 'Categoría',
              sub: filter.categories.isEmpty
                  ? 'Todas'
                  : filter.categories.map((c) => c.name).join(', '),
              icon: MusubiIcons.sparkle,
            ),
            MusubiOption(
              value: 'budget',
              label: 'Presupuesto',
              sub: filter.budget.label,
              icon: MusubiIcons.arrowDownUp,
            ),
            MusubiOption(
              value: 'deadline',
              label: 'Fecha límite',
              sub: filter.deadline.label,
              icon: MusubiIcons.calendar,
            ),
          ],
          onPick: (value) => Navigator.of(context).pop(value),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 240));
    if (!mounted) return;
    await switch (picked) {
      'category' => _pickCategories(),
      'budget' => _pickBudget(),
      _ => _pickDeadline(),
    };
  }

  Future<void> _pickCategories() async {
    final messenger = ScaffoldMessenger.of(context);
    final List<CatalogCategory> categories;
    try {
      categories = [
        ...await ref.read(categoriesProvider.future),
        otherCategory,
      ];
    } on ApiFailure catch (failure) {
      showMusubiSnack(
        messenger,
        failure.message,
        icon: MusubiIcons.circleAlert,
      );
      return;
    }
    if (!mounted) return;
    final filter = ref.read(wantedBoardFilterProvider);
    var selected = {for (final c in filter.categories) c.slug};
    final apply = await showMusubiPanel<bool>(
      context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) => MusubiPanel(
          key: const Key('wanted-categories'),
          title: 'Categoría',
          bodyInset: 12,
          actions: [
            MusubiButton(
              key: const Key('wanted-categories-apply'),
              label: 'Ver solicitudes',
              height: MusubiSizes.buttonHeightSheet,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
          child: MusubiMultiOptions<String>(
            options: [
              for (final c in categories)
                MusubiOption(value: c.slug, label: c.name),
            ],
            selected: selected,
            onChanged: (next) => setSheet(() => selected = next),
          ),
        ),
      ),
    );
    if (apply != true || !mounted) return;
    ref
        .read(wantedBoardFilterProvider.notifier)
        .apply(
          filter.copyWith(
            categories: [
              for (final c in categories)
                if (selected.contains(c.slug)) c,
            ],
          ),
        );
  }

  Future<void> _pickBudget() async {
    final filter = ref.read(wantedBoardFilterProvider);
    final picked = await showMusubiPanel<WantedBudget>(
      context,
      builder: (context) => MusubiPanel(
        key: const Key('wanted-budget'),
        title: 'Presupuesto',
        bodyInset: 12,
        child: MusubiOptions<WantedBudget>(
          selected: filter.budget,
          options: [
            for (final b in WantedBudget.values)
              MusubiOption(value: b, label: b.label),
          ],
          onPick: (value) => Navigator.of(context).pop(value),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    ref
        .read(wantedBoardFilterProvider.notifier)
        .apply(ref.read(wantedBoardFilterProvider).copyWith(budget: picked));
  }

  Future<void> _pickDeadline() async {
    final filter = ref.read(wantedBoardFilterProvider);
    final picked = await showMusubiPanel<WantedDeadline>(
      context,
      builder: (context) => MusubiPanel(
        key: const Key('wanted-deadline'),
        title: 'Fecha límite',
        bodyInset: 12,
        child: MusubiOptions<WantedDeadline>(
          selected: filter.deadline,
          options: [
            for (final d in WantedDeadline.values)
              MusubiOption(value: d, label: d.label),
          ],
          onPick: (value) => Navigator.of(context).pop(value),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    ref
        .read(wantedBoardFilterProvider.notifier)
        .apply(ref.read(wantedBoardFilterProvider).copyWith(deadline: picked));
  }
}

/// Encabezado de `Se-busca`: "Se busca", el campus verificado, la lupa y
/// "Filtrar" con el numero de filtros activos.
class _MemberHeader extends StatelessWidget {
  const new({
    required this.filters,
    required this.searching,
    required this.onSearch,
    required this.onFilter,
  });

  final int filters;
  final bool searching;
  final VoidCallback onSearch;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    Widget button({
      required Key key,
      required String label,
      required MusubiIconData icon,
      required VoidCallback onTap,
      int badge = 0,
    }) => Pressable(
      key: key,
      onTap: onTap,
      semanticLabel: label,
      builder: (context, _) => SizedBox.square(
        dimension: MusubiSizes.minTouch,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: MusubiIcon(
                icon,
                size: 22,
                strokeWidth: 1.9,
                color: c.textPrimary,
              ),
            ),
            if (badge > 0)
              Positioned(
                top: 4,
                right: 2,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 18),
                  height: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: c.brand,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$badge',
                    style: MusubiType.style(
                      10,
                      weight: FontWeight.w800,
                      color: c.onBrand,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Con letra grande el titulo se reduce antes que desbordar.
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Semantics(
                header: true,
                child: Text(
                  'Se busca',
                  style: MusubiType.style(
                    28,
                    weight: FontWeight.w800,
                    line: 34,
                    em: -0.03,
                    color: c.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          const CampusChip(signedIn: true),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              button(
                key: const Key('wanted-search'),
                label: searching ? 'Cerrar búsqueda' : 'Buscar solicitudes',
                icon: MusubiIcons.search,
                onTap: onSearch,
              ),
              button(
                key: const Key('wanted-filter'),
                label: filters == 0
                    ? 'Filtrar solicitudes'
                    : 'Filtrar solicitudes, $filters '
                          '${filters == 1 ? 'activo' : 'activos'}',
                icon: MusubiIcons.slidersHorizontal,
                onTap: onFilter,
                badge: filters,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// La lupa abierta (`data-sbsearch`): caja de 44 con radio 14.
class _SearchBox extends StatelessWidget {
  const new({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final style = MusubiType.style(15, weight: FontWeight.w600);
    return RiseIn(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          spacing: 8,
          children: [
            MusubiIcon(MusubiIcons.search, size: 18, color: c.textSecondary),
            Expanded(
              child: TextField(
                key: const Key('wanted-search-field'),
                controller: controller,
                focusNode: focusNode,
                onChanged: onChanged,
                textInputAction: TextInputAction.search,
                cursorColor: c.brand,
                style: style.copyWith(color: c.textPrimary),
                decoration: InputDecoration.collapsed(
                  hintText: 'Busca solicitudes: bata, laptop…',
                  hintStyle: style.copyWith(color: c.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "No hay solicitudes con estos filtros…" (`data-empty` de la maqueta).
class _NoMatches extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return RiseIn(
      child: Container(
        key: const Key('wanted-board-no-matches'),
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          'No hay solicitudes con estos filtros. Prueba con otros o publica '
          'lo que necesitas.',
          textAlign: TextAlign.center,
          style: MusubiType.style(
            14.5,
            weight: FontWeight.w600,
            line: 21,
            color: c.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Mientras carga: dos boletos en gris rojizo.
class _BoardLoading extends StatelessWidget {
  const new({required this.member});

  final bool member;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Cargando solicitudes',
    child: SkeletonShimmer(
      child: Column(
        spacing: 14,
        children: [
          for (var i = 0; i < 2; i++)
            SkeletonBox(height: member ? 250 : 236, radius: 22, brand: true),
        ],
      ),
    ),
  );
}

/// Si no se pudo cargar: el motivo en espanol y "Reintentar".
class _BoardError extends StatelessWidget {
  const new({required this.failure, required this.onRetry});

  final ApiFailure? failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    key: const Key('wanted-board-error'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 12,
    children: [
      InlineMessage(
        message: failure?.message ?? 'No pudimos cargar las solicitudes.',
      ),
      MusubiButton(
        label: 'Reintentar',
        kind: MusubiButtonKind.secondary,
        height: MusubiSizes.buttonHeightSmall,
        onPressed: onRetry,
      ),
    ],
  );
}

/// Encabezado rojo de `Se-busca-visitante`: campus, "Entrar", "Se busca",
/// "Tu campus lo pide. Tú lo tienes." y los tres pasos.
class _VisitorHero extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.brand,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          // Megafono de fondo: 230 px, girado -14 grados y casi transparente.
          Positioned(
            right: -56,
            top: 30,
            child: Transform.rotate(
              angle: -14 * math.pi / 180,
              child: MusubiIcon(
                MusubiIcons.megaphone,
                size: 230,
                strokeWidth: 1.3,
                color: c.onBrand.withValues(alpha: 0.13),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, top, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: MusubiSizes.minTouch,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const CampusChip(
                        signedIn: false,
                        onBrand: true,
                        returnTo: AppRoutes.wanted,
                      ),
                      _EnterButton(
                        onTap: () => context.go(
                          Uri(
                            path: AppRoutes.signIn,
                            queryParameters: {
                              AppRoutes.returnParam: AppRoutes.wanted,
                            },
                          ).toString(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Semantics(
                  header: true,
                  child: Text(
                    'Se busca',
                    style: MusubiType.style(
                      30,
                      weight: FontWeight.w800,
                      line: 36,
                      em: -0.03,
                      color: c.onBrand,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tu campus lo pide. Tú lo tienes.',
                  style: MusubiType.style(
                    16,
                    weight: FontWeight.w600,
                    line: 22,
                    color: c.onBrand,
                  ),
                ),
                const SizedBox(height: 18),
                Semantics(
                  label: 'Cómo funciona',
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 10,
                    children: [
                      for (final (i, (icon, label)) in const [
                        (MusubiIcons.megaphone, 'Alguien lo pide'),
                        (MusubiIcons.hand, 'Tú lo ofreces'),
                        (MusubiIcons.handshake, 'Se lo vendes'),
                      ].indexed)
                        Expanded(
                          child: RiseIn(
                            duration: const Duration(milliseconds: 450),
                            delay: Duration(milliseconds: i * 80),
                            child: _Step(
                              icon: icon,
                              label: label,
                              arrow: i < 2,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Paso de "Cómo funciona": circulo blanco con el icono y la etiqueta; los
/// dos primeros llevan la flecha al siguiente.
class _Step extends StatelessWidget {
  const new({required this.icon, required this.label, required this.arrow});

  final MusubiIconData icon;
  final String label;
  final bool arrow;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          decoration: BoxDecoration(
            color: c.brandDeep,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            spacing: 8,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: c.onBrand,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: MusubiIcon(icon, size: 20, color: c.brand),
                ),
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                style: MusubiType.style(
                  12.5,
                  weight: FontWeight.w700,
                  line: 16,
                  color: c.onBrand,
                ),
              ),
            ],
          ),
        ),
        if (arrow)
          Positioned(
            right: -13,
            top: 32,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: c.onBrand,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: MusubiIcon(
                  MusubiIcons.chevronRight,
                  size: 11,
                  strokeWidth: 3.4,
                  color: c.brand,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// "Entrar" blanco sobre el rojo (`.pw`).
class _EnterButton extends StatelessWidget {
  const new({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Pressable(
      key: const Key('wanted-enter'),
      semanticLabel: 'Entrar',
      onTap: onTap,
      builder: (context, pressed) => SizedBox(
        height: MusubiSizes.minTouch,
        child: Center(
          child: Container(
            height: 38,
            padding: const EdgeInsets.only(left: 12, right: 15),
            decoration: BoxDecoration(
              color: pressed ? c.brandSoft : c.onBrand,
              borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: [
                MusubiIcon(MusubiIcons.userRound, size: 18, color: c.brand),
                Text(
                  'Entrar',
                  style: MusubiType.style(
                    14,
                    weight: FontWeight.w800,
                    color: c.brand,
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

/// Tarjeta oscura "¿Necesitas algo?" con "Pedir algo".
class _NeedSomethingCard extends StatelessWidget {
  const new({required this.onAsk});

  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    const white = Color(0xFFFFFFFF);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.inverse,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: c.brand,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: MusubiIcon(MusubiIcons.megaphone, color: white),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '¿Necesitas algo?',
            style: MusubiType.style(
              19,
              weight: FontWeight.w800,
              line: 24,
              em: -0.02,
              color: white,
            ),
          ),
          const SizedBox(height: 14),
          MusubiButton(
            key: const Key('wanted-ask'),
            label: 'Pedir algo',
            height: 50,
            fontSize: 15,
            icon: MusubiIcons.plus,
            iconStrokeWidth: 2.4,
            onPressed: onAsk,
          ),
        ],
      ),
    );
  }
}
