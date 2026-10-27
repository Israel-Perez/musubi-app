import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/feedback_views.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/features/listings/domain/listing_models.dart';
import 'package:musubi_app/features/listings/presentation/listings_providers.dart';
import 'package:musubi_app/features/listings/presentation/sell_draft.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/home_cards.dart';

/// Pestanas de "Mis productos" (maqueta `Mis-productos`).
enum _MyTab { active, sold, soldOut }

/// `Mis-productos`: tus publicaciones por estado.
///
/// NOTE (HU-08): "Vendidos" llega con los pedidos (HU-23) y "Llevan tiempo
/// sin venderse" con las vistas y los mensajes (HU-11, HU-20).
/// NOTE (HU-50): cambiar las piezas desde la lista.
class MyProductsScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends ConsumerState<MyProductsScreen> {
  _MyTab _tab = _MyTab.active;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final mine = ref.watch(myListingsProvider);
    final all = mine.value ?? const <OwnListing>[];
    final active = [
      for (final l in all)
        if (l.status == ListingStatus.active) l,
    ];
    final soldOut = [
      for (final l in all)
        if (l.status == ListingStatus.soldOut) l,
    ];
    final shown = switch (_tab) {
      _MyTab.active => active,
      _MyTab.soldOut => soldOut,
      _MyTab.sold => const <OwnListing>[],
    };
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SizedBox(
                height: MusubiSizes.minTouch,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Pressable(
                      onTap: () => context.pop(),
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
                    Flexible(
                      child: Semantics(
                        header: true,
                        child: Text(
                          'Mis productos',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: MusubiType.style(
                            17,
                            weight: FontWeight.w800,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    Pressable(
                      onTap: () {
                        ref.read(sellDraftProvider.notifier).start();
                        unawaited(context.push(AppRoutes.sell));
                      },
                      semanticLabel: 'Vender',
                      builder: (context, _) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          spacing: 4,
                          children: [
                            MusubiIcon(
                              MusubiIcons.plus,
                              size: 18,
                              strokeWidth: 2.4,
                              color: c.textPrimary,
                            ),
                            Text(
                              'Vender',
                              style: MusubiType.style(
                                14,
                                weight: FontWeight.w800,
                                color: c.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: _Tabs(
                tab: _tab,
                counts: (active.length, 0, soldOut.length),
                onSelect: (tab) => setState(() => _tab = tab),
              ),
            ),
            Expanded(
              child: switch (mine) {
                AsyncError(:final error) => ErrorView(
                  message: error is ApiFailure
                      ? error.message
                      : 'No pudimos cargar tus productos.',
                  onRetry: () => ref.invalidate(myListingsProvider),
                ),
                AsyncData() when shown.isEmpty => EmptyView(
                  title: _tab == _MyTab.active
                      ? 'Aún no publicas nada'
                      : 'Nada por aquí',
                  message: _tab == _MyTab.sold
                      ? 'Aquí verás lo que vendas en Musubi.'
                      : 'Publica algo que ya no uses: fotos, precio y listo.',
                  icon: MusubiIcons.tag,
                  actionLabel: 'Vender un producto',
                  onAction: () {
                    ref.read(sellDraftProvider.notifier).start();
                    unawaited(context.push(AppRoutes.sell));
                  },
                ),
                AsyncData() => RefreshIndicator(
                  color: c.brand,
                  onRefresh: () => ref.refresh(myListingsProvider.future),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'Tu inventario',
                          style: MusubiType.style(
                            16,
                            weight: FontWeight.w800,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                      for (final listing in shown)
                        _InventoryRow(product: listing.product),
                    ],
                  ),
                ),
                _ => const LoadingView(message: 'Cargando tus productos…'),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const new({required this.tab, required this.counts, required this.onSelect});

  final _MyTab tab;
  final (int, int, int) counts;
  final ValueChanged<_MyTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final (active, sold, soldOut) = counts;
    final labels = {
      _MyTab.active: 'Activos ($active)',
      _MyTab.sold: 'Vendidos ($sold)',
      _MyTab.soldOut: 'Agotados ($soldOut)',
    };
    return Container(
      height: MusubiSizes.minTouch,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(MusubiSizes.radiusField),
      ),
      child: Row(
        spacing: 3,
        children: [
          for (final MapEntry(key: value, value: label) in labels.entries)
            Expanded(
              child: Pressable(
                onTap: () => onSelect(value),
                selected: value == tab,
                semanticLabel: label,
                builder: (context, _) => AnimatedContainer(
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
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MusubiType.style(
                      13.5,
                      weight: value == tab ? FontWeight.w800 : FontWeight.w600,
                      color: value == tab ? c.textPrimary : c.textSecondary,
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

/// Fila de "Tu inventario": foto de 52, nombre y "$180 · Quedan 2".
class _InventoryRow extends StatelessWidget {
  const new({required this.product});

  final ProductSummary product;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final few = product.stock > 0 && product.stock <= 2;
    final detail = product.soldOut
        ? 'Agotado'
        : few
        ? product.stockLabel ?? ''
        : product.stock == 1
        ? '1 disponible'
        : '${product.stock} disponibles';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.divider)),
      ),
      child: Row(
        spacing: 12,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(MusubiSizes.radiusThumb),
            child: SizedBox.square(
              dimension: 52,
              child: ProductPhoto(
                url: product.photoUrl,
                soldOut: product.soldOut,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  product.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MusubiType.style(
                    14,
                    weight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
                Text(
                  '${formatPrice(product.priceCents)} · $detail',
                  style: MusubiType.style(
                    12,
                    weight: few ? FontWeight.w800 : FontWeight.w600,
                    color: few ? c.warningText : c.textSecondary,
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
