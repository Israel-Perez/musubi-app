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

/// `Mis-productos`: tus publicaciones por pestana (HU-08: "Activos",
/// "Vendidos" y "Agotados" con los conteos de la API). Al tocar una, su menu
/// (HU-07 y HU-08): "Ver publicación", "Editar", "Marcar como vendido",
/// "Pausar publicación" o "Reactivar" y "Eliminar". Una vendida solo se ve
/// o se elimina.
///
/// NOTE (HU-25): en "Vendidos", el comprador y el monto real del pedido; hoy
/// se suma el precio publicado.
/// NOTE (HU-11): "Llevan tiempo sin venderse" con las vistas y los mensajes.
/// NOTE (HU-50): cambiar las piezas desde la lista.
class MyProductsScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<MyProductsScreen> createState() => _MyProductsScreenState();
}

class _MyProductsScreenState extends ConsumerState<MyProductsScreen> {
  MyProductsTab _tab = MyProductsTab.active;

  /// Paginas siguientes de la pestana ("Ver más").
  final List<OwnListing> _more = [];
  String? _moreCursor;
  bool _loadingMore = false;

  /// Ultimos conteos: no parpadean a 0 mientras carga otra pestana.
  MyListingsCounts _counts = const MyListingsCounts();

  void _select(MyProductsTab tab) => setState(() {
    _tab = tab;
    _more.clear();
    _moreCursor = null;
  });

  /// Despues de cambiar una publicacion: las pestanas, el Perfil y la vitrina.
  void _refreshAll() {
    setState(() {
      _more.clear();
      _moreCursor = null;
    });
    ref
      ..invalidate(myListingsTabProvider)
      ..invalidate(myListingsProvider)
      ..invalidate(homeFeedProvider);
  }

  /// "Ver más": la siguiente pagina de la pestana.
  Future<void> _loadMore(String cursor) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _loadingMore = true);
    try {
      final page = await ref
          .read(listingsRepositoryProvider)
          .minePage(_tab, cursor: cursor);
      if (!mounted) return;
      setState(() {
        _more.addAll(page.items);
        _moreCursor = page.nextCursor ?? '';
        _loadingMore = false;
      });
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      _failed(messenger, failure);
    }
  }

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
            // Una vendida no se edita, no se pausa ni se vende otra vez (409
            // `listings.product_sold`): solo se ve o se elimina.
            if (!listing.sold) ...[
              const MusubiOption(
                value: 'edit',
                label: 'Editar',
                icon: MusubiIcons.fileText,
              ),
              const MusubiOption(
                value: 'sold',
                label: 'Marcar como vendido',
                icon: MusubiIcons.check,
              ),
            ],
            // La maqueta no lo dibuja; la API lo tiene (decision de la
            // usuaria, 10-Nov-2026).
            if (!listing.sold)
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
      case 'sold':
        await _markSold(listing);
      case 'pause':
        await _setPaused(listing, paused: true);
      case 'resume':
        await _setPaused(listing, paused: false);
      case 'delete':
        await _delete(listing);
    }
  }

  /// "Marcar como vendido" con el dialogo de la maqueta (`Producto`, HU-08).
  Future<void> _markSold(OwnListing listing) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showMusubiDialog(
      context,
      icon: MusubiIcons.shoppingBag,
      title: '¿Marcar como vendido?',
      message: 'Ya no aparecerá en las búsquedas y se moverá a tus ventas.',
      confirmLabel: 'Sí, ya lo vendí',
      confirmKey: const Key('my-product-sold-confirm'),
    );
    if (!confirmed || !mounted) return;
    try {
      await ref.read(listingsRepositoryProvider).markSold(listing.product.id);
    } on ApiFailure catch (failure) {
      _failed(messenger, failure);
      return;
    }
    _refreshAll();
    showMusubiSnack(messenger, '¡Felicidades por tu venta!');
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
    _refreshAll();
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
    _refreshAll();
    showMusubiSnack(
      messenger,
      'Eliminaste la publicación',
      icon: MusubiIcons.x,
      tone: SnackTone.info,
    );
  }

  /// El mensaje de la API; si ya no existe, la lista se refresca.
  void _failed(ScaffoldMessengerState messenger, ApiFailure failure) {
    // Ya no existe, o ya se vendio en otro telefono: la lista se refresca.
    if (failure.code == 'listings.product_not_found' ||
        failure.code == 'listings.product_sold') {
      _refreshAll();
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
    // HU-08: cada pestana la arma la API (Activos = disponibles y pausadas).
    final mine = ref.watch(myListingsTabProvider(_tab));
    if (mine.value case final page?) _counts = page.counts;
    final first = mine.value;
    final shown = [...?first?.items, ..._more];
    final cursor = _moreCursor == null
        ? first?.nextCursor
        : (_moreCursor!.isEmpty ? null : _moreCursor);
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
                counts: (_counts.active, _counts.sold, _counts.soldOut),
                onSelect: _select,
              ),
            ),
            Expanded(
              child: switch (mine) {
                AsyncError(:final error) => ErrorView(
                  message: error is ApiFailure
                      ? error.message
                      : 'No pudimos cargar tus productos.',
                  onRetry: () => ref.invalidate(myListingsTabProvider(_tab)),
                ),
                AsyncData() when shown.isEmpty => EmptyView(
                  title: _tab == MyProductsTab.active
                      ? 'Aún no publicas nada'
                      : 'Nada por aquí',
                  message: _tab == MyProductsTab.sold
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
                  onRefresh: () {
                    _refreshAll();
                    return ref.read(myListingsTabProvider(_tab).future);
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                    children: [
                      if (_tab == MyProductsTab.sold)
                        _SalesTotal(
                          count: _counts.sold,
                          totalCents: shown.fold(
                            0,
                            (sum, l) => sum + l.product.priceCents,
                          ),
                        )
                      else
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
                      if (cursor != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: MusubiButton(
                            key: const Key('my-products-more'),
                            label: 'Ver más',
                            kind: MusubiButtonKind.secondary,
                            loading: _loadingMore,
                            onPressed: () => unawaited(_loadMore(cursor)),
                          ),
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

  final MyProductsTab tab;
  final (int, int, int) counts;
  final ValueChanged<MyProductsTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final (active, sold, soldOut) = counts;
    final labels = {
      MyProductsTab.active: 'Activos ($active)',
      MyProductsTab.sold: 'Vendidos ($sold)',
      MyProductsTab.soldOut: 'Agotados ($soldOut)',
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
    final few = !listing.sold && product.stock > 0 && product.stock <= 2;
    final stock = product.soldOut
        ? 'Agotado'
        : few
        ? product.stockLabel ?? ''
        : product.stock == 1
        ? '1 disponible'
        : '${product.stock} disponibles';
    final detail = switch (listing) {
      OwnListing(sold: true, :final soldAt?) => dayMonth(soldAt.toLocal()),
      OwnListing(sold: true) => 'Vendido',
      OwnListing(paused: true) => 'Pausada · $stock',
      _ => stock,
    };
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
                soldOut: !listing.sold && (product.soldOut || listing.paused),
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
          // Maqueta `Mis-productos` → "Vendidos": la marca a la derecha.
          if (listing.sold)
            Text(
              'Vendido',
              style: MusubiType.style(
                12,
                weight: FontWeight.w800,
                color: c.successText,
              ),
            ),
        ],
      ),
    );
  }
}

/// "N ventas" y el total, arriba de "Vendidos" (maqueta `Mis-productos`).
/// NOTE (HU-25): el monto real llega con los pedidos; hoy es el precio
/// publicado de las vendidas que se ven.
class _SalesTotal extends StatelessWidget {
  const new({required this.count, required this.totalCents});

  final int count;
  final int totalCents;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Container(
      key: const Key('my-products-sales'),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: c.successSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            count == 1 ? '1 venta' : '$count ventas',
            style: MusubiType.style(
              15,
              weight: FontWeight.w800,
              color: c.successText,
            ),
          ),
          Text(
            formatPrice(totalCents),
            style: MusubiType.style(
              22,
              weight: FontWeight.w800,
              color: c.successText,
            ),
          ),
        ],
      ),
    );
  }
}
