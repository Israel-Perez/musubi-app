import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/feedback_views.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/features/orders/domain/order_models.dart';
import 'package:musubi_app/features/orders/presentation/my_orders_widgets.dart';
import 'package:musubi_app/features/orders/presentation/order_providers.dart';

/// "Mis pedidos" (HU-25): mis compras por pestana (Activos, Completados y
/// Cancelados, decision de la usuaria del 12-Nov-2026). La maqueta no tiene
/// esta pantalla: se arma con las pestanas de `Mis-productos` y las filas de
/// la seccion "Mis pedidos" de `Perfil`. Las ventas son de HU-26.
class MyOrdersScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends ConsumerState<MyOrdersScreen> {
  MyOrdersTab _tab = MyOrdersTab.active;

  /// Paginas siguientes de la pestana ("Ver más").
  final List<Order> _more = [];
  String? _moreCursor;
  bool _loadingMore = false;

  /// Ultimos numeros: no parpadean a 0 mientras carga otra pestana.
  MyOrdersCounts _counts = const MyOrdersCounts();

  void _select(MyOrdersTab tab) => setState(() {
    _tab = tab;
    _more.clear();
    _moreCursor = null;
  });

  /// Al volver de un pedido: las pestanas y la seccion de `Perfil`.
  void _refreshAll() {
    setState(() {
      _more.clear();
      _moreCursor = null;
    });
    ref
      ..invalidate(myOrdersProvider)
      ..invalidate(recentOrdersProvider);
  }

  Future<void> _open(Order order) async {
    await context.push(AppRoutes.order(order.id));
    if (mounted) _refreshAll();
  }

  /// "Ver más": la siguiente pagina de la pestana.
  Future<void> _loadMore(String cursor) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _loadingMore = true);
    try {
      final page = await ref
          .read(orderRepositoryProvider)
          .mine(tab: _tab, cursor: cursor);
      if (!mounted) return;
      setState(() {
        _more.addAll(page.items);
        _moreCursor = page.nextCursor ?? '';
        _loadingMore = false;
      });
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      showMusubiSnack(
        messenger,
        failure.message,
        icon: MusubiIcons.circleAlert,
        tone: SnackTone.warn,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final mine = ref.watch(myOrdersProvider(_tab));
    if (mine.value case final page?) _counts = page.counts;
    final shown = [...?mine.value?.items, ..._more];
    final cursor = _moreCursor == null
        ? mine.value?.nextCursor
        : (_moreCursor!.isEmpty ? null : _moreCursor);
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(onBack: () => context.pop()),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: _Tabs(tab: _tab, counts: _counts, onSelect: _select),
            ),
            Expanded(
              child: switch (mine) {
                AsyncError(:final error) => ErrorView(
                  message: error is ApiFailure
                      ? error.message
                      : 'No pudimos cargar tus pedidos.',
                  onRetry: () => ref.invalidate(myOrdersProvider(_tab)),
                ),
                AsyncData() when shown.isEmpty => _Empty(tab: _tab),
                AsyncData() => RefreshIndicator(
                  color: c.brand,
                  onRefresh: () {
                    _refreshAll();
                    return ref.read(myOrdersProvider(_tab).future);
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    children: [
                      for (final order in shown)
                        OrderRow(
                          order: order,
                          onTap: () => unawaited(_open(order)),
                        ),
                      if (cursor != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: MusubiButton(
                            key: const Key('my-orders-more'),
                            label: 'Ver más',
                            kind: MusubiButtonKind.secondary,
                            loading: _loadingMore,
                            onPressed: () => unawaited(_loadMore(cursor)),
                          ),
                        ),
                    ],
                  ),
                ),
                _ => const LoadingView(message: 'Cargando tus pedidos…'),
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// "Regresar" y el titulo centrado, como `Mis-productos`.
class _Header extends StatelessWidget {
  const new({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        height: MusubiSizes.minTouch,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Pressable(
                onTap: onBack,
                semanticLabel: 'Regresar',
                builder: (context, _) => SizedBox.square(
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
            ),
            Semantics(
              header: true,
              child: Text(
                'Mis pedidos',
                style: MusubiType.style(
                  17,
                  weight: FontWeight.w800,
                  color: c.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Activos (2)", "Completados (5)" y "Cancelados (1)". El toque cubre los 44
/// de alto (RNF-27) y la pastilla de 38 queda a 3 del borde.
class _Tabs extends StatelessWidget {
  const new({required this.tab, required this.counts, required this.onSelect});

  final MyOrdersTab tab;
  final MyOrdersCounts counts;
  final ValueChanged<MyOrdersTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Container(
      height: MusubiSizes.minTouch,
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(MusubiSizes.radiusField),
      ),
      child: Row(
        spacing: 3,
        children: [
          for (final value in MyOrdersTab.values)
            Expanded(
              child: Pressable(
                key: Key('my-orders-tab-${value.code}'),
                onTap: () => onSelect(value),
                selected: value == tab,
                semanticLabel: '${value.label} (${counts.of(value)})',
                builder: (context, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: value == tab ? c.elevated : null,
                      borderRadius: BorderRadius.circular(11),
                      boxShadow: value == tab
                          ? const [
                              BoxShadow(
                                color: Color(0x1F1C1C1E),
                                offset: Offset(0, 1),
                                blurRadius: 3,
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      '${value.label} (${counts.of(value)})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MusubiType.style(
                        13.5,
                        weight: value == tab
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: value == tab ? c.textPrimary : c.textSecondary,
                      ),
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

/// Cada pestana vacia explica que va ahi; en Activos, lleva a Inicio.
class _Empty extends StatelessWidget {
  const new({required this.tab});

  final MyOrdersTab tab;

  @override
  Widget build(BuildContext context) => switch (tab) {
    MyOrdersTab.active => EmptyView(
      title: 'Sin pedidos en curso',
      message: 'Cuando pidas algo desde el chat, aquí verás cómo va.',
      icon: MusubiIcons.package,
      actionLabel: 'Ver productos',
      onAction: () => context.go(AppRoutes.home),
    ),
    MyOrdersTab.completed => const EmptyView(
      title: 'Aún no completas un pedido',
      message: 'Aquí quedan las compras que ya recibiste.',
      icon: MusubiIcons.circleCheck,
    ),
    MyOrdersTab.cancelled => const EmptyView(
      title: 'Sin pedidos cancelados',
      message: 'Aquí quedan los pedidos que se cancelaron.',
      icon: MusubiIcons.circleX,
    ),
  };
}
