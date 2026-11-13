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
import 'package:musubi_app/features/listings/presentation/quantity_row.dart';
import 'package:musubi_app/features/listings/presentation/sell_draft.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/home_cards.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';
import 'package:musubi_app/features/orders/domain/order_models.dart';
import 'package:musubi_app/features/orders/presentation/order_providers.dart';

/// `Mis-productos`: tus publicaciones por pestana (HU-08: "Activos",
/// "Vendidos" y "Agotados" con los conteos de la API). Al tocar una, su menu
/// (HU-07 y HU-08): "Ver publicación", "Editar", "Marcar como vendido",
/// "Pausar publicación" o "Reactivar" y "Eliminar". Una vendida solo se ve
/// o se elimina.
///
/// HU-26: "Vendidos" empieza con mis ventas completadas (quien compro, las
/// piezas, el monto y la fecha; al tocar una, "Tu venta") y la tarjeta con su
/// numero y su total real; abajo, lo marcado como vendido a mano.
/// NOTE (HU-11): "Llevan tiempo sin venderse" con las vistas y los mensajes.
/// HU-50: "Cambiar piezas" en el menu y "Reponer" en las agotadas.
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

  /// Paginas siguientes de mis ventas (HU-26). El cursor sigue la regla de
  /// [_moreCursor]: `null` = aun no se pide, `''` = ya no hay mas.
  final List<Order> _moreSales = [];
  String? _salesCursor;

  /// Ultimos conteos: no parpadean a 0 mientras carga otra pestana.
  MyListingsCounts _counts = const MyListingsCounts();
  int _salesCount = 0;

  void _select(MyProductsTab tab) => setState(() {
    _tab = tab;
    _clearPages();
  });

  void _clearPages() {
    _more.clear();
    _moreCursor = null;
    _moreSales.clear();
    _salesCursor = null;
  }

  /// Despues de cambiar una publicacion: las pestanas, las ventas, el Perfil
  /// y la vitrina.
  void _refreshAll() {
    setState(_clearPages);
    ref
      ..invalidate(myListingsTabProvider)
      ..invalidate(salesProvider)
      ..invalidate(myListingsProvider)
      ..invalidate(homeFeedProvider);
  }

  /// "Ver más" en "Vendidos": la siguiente pagina de mis ventas.
  Future<void> _loadMoreSales(String cursor) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _loadingMore = true);
    try {
      final page = await ref
          .read(orderRepositoryProvider)
          .sales(cursor: cursor);
      if (!mounted) return;
      setState(() {
        _moreSales.addAll(page.items);
        _salesCursor = page.nextCursor ?? '';
        _loadingMore = false;
      });
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      _failed(messenger, failure);
    }
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
              MusubiOption(
                value: 'stock',
                label: 'Cambiar piezas',
                sub: listing.product.stock == 1
                    ? '1 pieza disponible'
                    : '${listing.product.stock} piezas disponibles',
                icon: MusubiIcons.package,
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
      case 'stock':
        await _changeStock(listing);
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

  /// "Cambiar piezas" (HU-50): el selector de `Vender-4` de 0 a 10. Las
  /// apartadas en un pedido aceptado ya no cuentan (HU-24).
  Future<void> _changeStock(OwnListing listing) async {
    final stock = await showMusubiPanel<int>(
      context,
      builder: (context) => _StockPanel(initial: listing.product.stock),
    );
    if (stock == null || stock == listing.product.stock || !mounted) return;
    await _setStock(
      listing,
      stock,
      done: stock == 0
          ? 'Guardamos las piezas. Ya aparece como agotado.'
          : 'Guardamos las piezas disponibles.',
    );
  }

  /// "Reponer" en una agotada (maqueta: la deja con 1 pieza).
  Future<void> _restock(OwnListing listing) => _setStock(
    listing,
    1,
    done: 'Repusiste «${listing.product.title}». Ya está disponible',
  );

  Future<void> _setStock(
    OwnListing listing,
    int stock, {
    required String done,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(listingsRepositoryProvider)
          .setStock(listing.product.id, stock);
    } on ApiFailure catch (failure) {
      _failed(messenger, failure);
      return;
    }
    _refreshAll();
    showMusubiSnack(messenger, done);
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
    // HU-26: las ventas completadas tambien cuentan en "Vendidos (n)".
    final sales = ref.watch(salesProvider);
    if (sales.value case final page?) _salesCount = page.count;
    final soldTab = _tab == MyProductsTab.sold;
    final firstSales = soldTab ? sales.value : null;
    final shownSales = [...?firstSales?.items, if (soldTab) ..._moreSales];
    final salesNext = !soldTab
        ? null
        : _salesCursor == null
        ? firstSales?.nextCursor
        : (_salesCursor!.isEmpty ? null : _salesCursor);
    final first = mine.value;
    // Lo marcado a mano sale despues de la ultima venta.
    final shown = salesNext == null
        ? [...?first?.items, ..._more]
        : const <OwnListing>[];
    final cursor = _moreCursor == null
        ? first?.nextCursor
        : (_moreCursor!.isEmpty ? null : _moreCursor);
    void retry() {
      ref.invalidate(myListingsTabProvider(_tab));
      if (soldTab) ref.invalidate(salesProvider);
    }

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
                counts: (
                  _counts.active,
                  _counts.sold + _salesCount,
                  _counts.soldOut,
                ),
                onSelect: _select,
              ),
            ),
            Expanded(
              child: switch (mine) {
                AsyncError(:final error) => _ErrorView(
                  error: error,
                  onRetry: retry,
                ),
                _ when soldTab && sales.hasError => _ErrorView(
                  error: sales.error,
                  onRetry: retry,
                ),
                AsyncData() when soldTab && !sales.hasValue =>
                  const LoadingView(message: 'Cargando tus productos…'),
                AsyncData() when shown.isEmpty && shownSales.isEmpty =>
                  EmptyView(
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
                  onRefresh: () async {
                    _refreshAll();
                    await ref.read(myListingsTabProvider(_tab).future);
                    if (soldTab) await ref.read(salesProvider.future);
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                    children: [
                      if (soldTab)
                        // La tarjeta: las ventas completadas y su total real.
                        if (firstSales
                            case SalesPage(:final count, :final totalCents)
                            when count > 0)
                          _SalesTotal(count: count, totalCents: totalCents)
                        else
                          const SizedBox.shrink()
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
                      for (final sale in shownSales)
                        _SaleRow(
                          order: sale,
                          onTap: () =>
                              unawaited(context.push(AppRoutes.order(sale.id))),
                        ),
                      for (final listing in shown)
                        _InventoryRow(
                          listing: listing,
                          onTap: () => unawaited(_manage(listing)),
                          // HU-50: "Reponer" en las agotadas (maqueta).
                          onRestock: listing.status == ListingStatus.soldOut
                              ? () => unawaited(_restock(listing))
                              : null,
                        ),
                      // Primero las ventas que faltan y luego lo marcado a
                      // mano.
                      if (salesNext ?? cursor case final next?)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: MusubiButton(
                            key: const Key('my-products-more'),
                            label: 'Ver más',
                            kind: MusubiButtonKind.secondary,
                            loading: _loadingMore,
                            onPressed: () => unawaited(
                              salesNext != null
                                  ? _loadMoreSales(next)
                                  : _loadMore(next),
                            ),
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
  const new({required this.listing, required this.onTap, this.onRestock});

  final OwnListing listing;
  final VoidCallback onTap;

  /// "Reponer" (HU-50), solo en una agotada.
  final VoidCallback? onRestock;

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
    // HU-26: las vendidas por un pedido salen como venta; aqui queda lo
    // marcado a mano, sin comprador.
    final detail = switch (listing) {
      OwnListing(sold: true, :final soldAt?) =>
        '${dayMonth(soldAt.toLocal())} · Marcado a mano',
      OwnListing(sold: true) => 'Marcado a mano',
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
          // Maqueta `Mis-productos` → "Agotados": "Reponer" a la derecha.
          if (onRestock case final restock?)
            Pressable(
              key: Key('my-product-restock-${product.id}'),
              onTap: restock,
              semanticLabel: 'Reponer ${product.title}',
              builder: (context, _) => Container(
                height: MusubiSizes.minTouch,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.inverse,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Reponer',
                  style: MusubiType.style(
                    13.5,
                    weight: FontWeight.w800,
                    color: const Color(0xFFFFFFFF),
                  ),
                ),
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

/// La pantalla de error de una pestana, con el mensaje de la API.
class _ErrorView extends StatelessWidget {
  const new({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ErrorView(
    message: switch (error) {
      ApiFailure(:final message) => message,
      _ => 'No pudimos cargar tus productos.',
    },
    onRetry: onRetry,
  );
}

/// Una venta completada (HU-26): foto de 52, nombre, "$900 · 10 nov · 2
/// piezas · Ana Sofía Ramírez" y la marca "Vendido". Al tocarla, "Tu venta"
/// (`Pedido-pago`).
class _SaleRow extends StatelessWidget {
  const new({required this.order, required this.onTap});

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final item = order.item;
    final line = [
      formatPrice(item.totalCents),
      dayMonth((order.updatedAt ?? order.deliveryAt).toLocal()),
      if (item.quantity > 1) '${item.quantity} piezas',
      order.buyerName,
    ].join(' · ');
    return Pressable(
      key: Key('my-sale-${order.id}'),
      onTap: onTap,
      semanticLabel: '${item.title}, $line. Ver la venta',
      builder: (context, _) => Container(
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
                child: ProductPhoto(url: item.photoUrl),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MusubiType.style(
                      14,
                      weight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                  Text(
                    line,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MusubiType.style(
                      12,
                      weight: FontWeight.w600,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
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
      ),
    );
  }
}

/// "N ventas" y el total real de mis ventas completadas, arriba de
/// "Vendidos" (maqueta `Mis-productos`, HU-26).
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

/// "Cambiar piezas" (HU-50): "Piezas disponibles" de 0 a 10 y "Guardar".
/// Devuelve las piezas elegidas al cerrar.
class _StockPanel extends StatefulWidget {
  const new({required this.initial});

  final int initial;

  @override
  State<_StockPanel> createState() => _StockPanelState();
}

class _StockPanelState extends State<_StockPanel> {
  late int _stock = widget.initial.clamp(0, SellDraft.maxQuantity);

  @override
  Widget build(BuildContext context) => MusubiPanel(
    key: const Key('my-product-stock'),
    title: 'Cambiar piezas',
    bodyInset: 12,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QuantityRow(
          quantity: _stock,
          min: 0,
          margin: EdgeInsets.zero,
          note: _stock == 0
              ? 'Con 0 queda como agotado'
              : 'Las apartadas en un pedido ya no cuentan',
          onStep: (delta) => setState(
            () => _stock = (_stock + delta).clamp(0, SellDraft.maxQuantity),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: MusubiButton(
            key: const Key('my-product-stock-save'),
            label: 'Guardar',
            onPressed: () => Navigator.of(context).pop(_stock),
          ),
        ),
      ],
    ),
  );
}
