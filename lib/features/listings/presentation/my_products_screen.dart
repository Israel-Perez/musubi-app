import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/feedback_views.dart';
import 'package:musubi_app/core/widgets/musubi_dialog.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_panel.dart';
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/features/listings/domain/listing_models.dart';
import 'package:musubi_app/features/listings/presentation/listings_providers.dart';
import 'package:musubi_app/features/listings/presentation/sell_draft.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/home_cards.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';

/// Pestanas de "Mis productos" (maqueta `Mis-productos`).
enum _MyTab { active, sold, soldOut }

/// `Mis-productos`: tus publicaciones por estado. Al tocar una, su menu
/// (HU-07): "Ver publicación", "Editar", "Pausar publicación" o "Reactivar"
/// y "Eliminar".
///
/// NOTE (HU-08): "Vendidos" y "Marcar como vendido" con las filas de
/// `musubi-api:HU-08`; "Llevan tiempo sin venderse" con las vistas y los
/// mensajes (HU-11, HU-20).
/// NOTE (HU-50): cambiar las piezas desde la lista.
class MyProductsScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends ConsumerState<MyProductsScreen> {
  _MyTab _tab = _MyTab.active;

  /// Menu de una publicacion (maqueta: `UI.options` con su nombre corto).
  Future<void> _manage(OwnListing listing) async {
    final picked = await showMusubiPanel<String>(
      context,
      builder: (context) => MusubiPanel(
        key: const Key('my-product-manage'),
        title: listing.product.title,
        bodyInset: 12,
        child: MusubiOptions<String>(
          plain: true,
          options: [
            const MusubiOption(
              value: 'view',
              label: 'Ver publicación',
              icon: MusubiIcons.image,
            ),
            const MusubiOption(
              value: 'edit',
              label: 'Editar',
              icon: MusubiIcons.fileText,
            ),
            // La maqueta no lo dibuja; la API lo tiene (decision de la
            // usuaria, 10-Nov-2026).
            if (listing.paused)
              const MusubiOption(
                value: 'resume',
                label: 'Reactivar',
                sub: 'Vuelve a verse en Musubi',
                icon: MusubiIcons.eye,
              )
            else
              const MusubiOption(
                value: 'pause',
                label: 'Pausar publicación',
                sub: 'Deja de verse; la reactivas cuando quieras',
                icon: MusubiIcons.eyeOff,
              ),
            const MusubiOption(
              value: 'delete',
              label: 'Eliminar',
              icon: MusubiIcons.x,
              danger: true,
            ),
          ],
          onPick: (value) => Navigator.of(context).pop(value),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    // Como el resto de las hojas: el siguiente paso abre 240 ms despues.
    await Future<void>.delayed(const Duration(milliseconds: 240));
    if (!mounted) return;
    switch (picked) {
      case 'view':
        unawaited(context.push(AppRoutes.product(listing.product.id)));
      case 'edit':
        ref.read(sellEditDraftProvider.notifier).load(listing);
        unawaited(context.push(AppRoutes.editListing));
      case 'pause':
        await _setPaused(listing, paused: true);
      case 'resume':
        await _setPaused(listing, paused: false);
      case 'delete':
        await _delete(listing);
    }
  }

  /// "Pausar publicación" o "Reactivar" (HU-07).
  Future<void> _setPaused(OwnListing listing, {required bool paused}) async {
    final messenger = ScaffoldMessenger.of(context);
    final repository = ref.read(listingsRepositoryProvider);
    try {
      await (paused
          ? repository.pause(listing.product.id)
          : repository.resume(listing.product.id));
    } on ApiFailure catch (failure) {
      _failed(messenger, failure);
      return;
    }
    ref
      ..invalidate(myListingsProvider)
      ..invalidate(homeFeedProvider);
    showMusubiSnack(
      messenger,
      paused
          ? 'Pausaste la publicación. Ya no se ve en Musubi.'
          : 'Reactivaste la publicación. Ya se ve en Musubi.',
      icon: paused ? MusubiIcons.eyeOff : MusubiIcons.check,
      tone: paused ? SnackTone.info : SnackTone.success,
    );
  }

  /// "Eliminar" con la confirmacion de la maqueta (HU-07).
  Future<void> _delete(OwnListing listing) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showMusubiDialog(
      context,
      icon: MusubiIcons.x,
      title: '¿Eliminar la publicación?',
      message: 'Ya no aparecerá en Musubi. Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      danger: true,
      confirmKey: const Key('my-product-delete-confirm'),
    );
    if (!confirmed || !mounted) return;
    try {
      await ref.read(listingsRepositoryProvider).delete(listing.product.id);
    } on ApiFailure catch (failure) {
      // RN-07 (HU-23): con pedidos abiertos la API explica que hacer.
      _failed(messenger, failure);
      return;
    }
    ref
      ..invalidate(myListingsProvider)
      ..invalidate(homeFeedProvider);
    showMusubiSnack(
      messenger,
      'Eliminaste la publicación',
      icon: MusubiIcons.x,
      tone: SnackTone.info,
    );
  }

  /// El mensaje de la API; si ya no existe, la lista se refresca.
  void _failed(ScaffoldMessengerState messenger, ApiFailure failure) {
    if (failure.code == 'listings.product_not_found') {
      ref.invalidate(myListingsProvider);
    }
    showMusubiSnack(
      messenger,
      failure.message,
      icon: MusubiIcons.circleAlert,
      tone: SnackTone.warn,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final mine = ref.watch(myListingsProvider);
    final all = mine.value ?? const <OwnListing>[];
    // Activos: disponibles y pausadas (la pausada lleva su marca).
    final active = [
      for (final l in all)
        if (l.status == ListingStatus.active || l.paused) l,
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
                        _InventoryRow(
                          listing: listing,
                          onTap: () => unawaited(_manage(listing)),
                        ),
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

/// Fila de "Tu inventario": foto de 52, nombre y "$180 · Quedan 2". Al
/// tocarla, su menu (HU-07).
class _InventoryRow extends StatelessWidget {
  const new({required this.listing, required this.onTap});

  final OwnListing listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final product = listing.product;
    final few = product.stock > 0 && product.stock <= 2;
    final stock = product.soldOut
        ? 'Agotado'
        : few
        ? product.stockLabel ?? ''
        : product.stock == 1
        ? '1 disponible'
        : '${product.stock} disponibles';
    final detail = listing.paused ? 'Pausada · $stock' : stock;
    return Pressable(
      key: Key('my-product-${product.id}'),
      onTap: onTap,
      semanticLabel: '${product.title}, $detail. Opciones',
      builder: (context, _) => _row(context, c, product, few, detail),
    );
  }

  Widget _row(
    BuildContext context,
    MusubiColors c,
    ProductSummary product,
    bool few,
    String detail,
  ) {
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
                soldOut: product.soldOut || listing.paused,
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
