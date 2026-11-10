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
import 'package:musubi_app/features/marketplace/domain/favorite_models.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/favorites_actions.dart';
import 'package:musubi_app/features/marketplace/presentation/favorites_providers.dart';
import 'package:musubi_app/features/marketplace/presentation/home_cards.dart';

/// `Favoritos` (HU-53): lo guardado, con Todos, Disponibles y Agotados.
class FavoritesScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final tab = ref.watch(favoriteTabProvider);
    final value = favorites.value ?? const Favorites();

    return Scaffold(
      backgroundColor: context.musubi.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              onBack: () => context.canPop()
                  ? context.pop()
                  : context.go(AppRoutes.profile),
            ),
            if (favorites.hasValue)
              _Tabs(
                tab: tab,
                counts: (
                  value.items.length,
                  value.availableCount,
                  value.soldOutCount,
                ),
                onSelect: (next) =>
                    ref.read(favoriteTabProvider.notifier).select(next),
              ),
            Expanded(
              child: switch (favorites) {
                AsyncData(:final value) => _List(favorites: value, tab: tab),
                AsyncError(:final error) when !favorites.hasValue => ErrorView(
                  message: error is ApiFailure
                      ? error.message
                      : 'No pudimos cargar tus favoritos.',
                  onRetry: () => ref.invalidate(favoritesProvider),
                ),
                _ => const LoadingView(message: 'Cargando tus favoritos…'),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const new({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 16, 0),
      child: Row(
        children: [
          Pressable(
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
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'Favoritos',
              style: MusubiType.style(
                24,
                weight: FontWeight.w800,
                line: 30,
                em: -0.025,
                color: c.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const new({required this.tab, required this.counts, required this.onSelect});

  final FavoriteTab tab;
  final (int, int, int) counts;
  final ValueChanged<FavoriteTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final (all, available, soldOut) = counts;
    final labels = {
      FavoriteTab.all: 'Todos ($all)',
      FavoriteTab.available: 'Disponibles ($available)',
      FavoriteTab.soldOut: 'Agotados ($soldOut)',
    };
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      height: MusubiSizes.minTouch + 6,
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
                key: Key('favorite-tab-${value.name}'),
                onTap: () => onSelect(value),
                selected: value == tab,
                semanticLabel: label,
                builder: (context, _) => Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: double.infinity,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: value == tab ? c.background : null,
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

class _List extends ConsumerWidget {
  const new({required this.favorites, required this.tab});

  final Favorites favorites;
  final FavoriteTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = switch (tab) {
      FavoriteTab.all => favorites.items,
      FavoriteTab.available => [
        for (final item in favorites.items)
          if (item.status == FavoriteStatus.available) item,
      ],
      FavoriteTab.soldOut => [
        for (final item in favorites.items)
          if (item.status != FavoriteStatus.available) item,
      ],
    };
    if (items.isEmpty) return _Empty(tab: tab);
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.paddingOf(context).bottom + 24,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 12,
        mainAxisExtent: 240,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _FavoriteTile(
          item: item,
          onRemove: () => unawaited(_remove(context, ref, item)),
          onOpen: item.product == null
              ? null
              : () => unawaited(
                  context.push(
                    AppRoutes.product(item.product!.id),
                    extra: item.product,
                  ),
                ),
        );
      },
    );
  }

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    FavoriteItem item,
  ) async {
    final product = item.product;
    if (product != null) {
      await toggleFavorite(context, ref, product);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(favoritesProvider.notifier).remove(item.productId);
      if (!context.mounted) return;
      showMusubiSnack(
        messenger,
        'Lo quitaste de Favoritos',
        icon: MusubiIcons.heart,
        tone: SnackTone.info,
      );
    } on ApiFailure catch (failure) {
      if (!context.mounted) return;
      showMusubiSnack(
        messenger,
        failure.message,
        icon: MusubiIcons.circleAlert,
        tone: SnackTone.warn,
      );
    }
  }
}

class _Empty extends StatelessWidget {
  const new({required this.tab});

  final FavoriteTab tab;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: c.brandSoft,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: MusubiIcon(
                  MusubiIcons.heart,
                  size: 30,
                  strokeWidth: 1.9,
                  color: c.brand,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tab == FavoriteTab.soldOut
                  ? 'Nada agotado'
                  : 'Aún no guardas nada',
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
              'Toca el corazón en cualquier producto para guardarlo aquí.',
              textAlign: TextAlign.center,
              style: MusubiType.style(14, line: 20, color: c.textSecondary),
            ),
            const SizedBox(height: 20),
            MusubiButton(
              label: 'Ver lo recién publicado',
              onPressed: () => context.go(AppRoutes.home),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteTile extends StatelessWidget {
  const new({required this.item, required this.onRemove, this.onOpen});

  final FavoriteItem item;
  final VoidCallback onRemove;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    if (product == null) {
      return _UnavailableTile(item: item, onRemove: onRemove);
    }
    final c = context.musubi;
    final soldOut = item.status == FavoriteStatus.soldOut;
    final stock = soldOut ? null : product.stockLabel;
    final card = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(MusubiSizes.radiusButton),
          child: SizedBox(
            height: 150,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ProductPhoto(url: product.photoUrl, soldOut: soldOut),
                if (product.condition != null)
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: c.overlayPill,
                        borderRadius: BorderRadius.circular(
                          MusubiSizes.radiusChip,
                        ),
                      ),
                      child: Text(
                        product.condition!,
                        style: MusubiType.style(
                          11,
                          weight: FontWeight.w700,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                  ),
                if (stock != null)
                  Positioned(
                    left: 8,
                    top: 8,
                    child: StockPill(label: stock, compact: true),
                  ),
                if (soldOut)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: c.inverse,
                        borderRadius: BorderRadius.circular(
                          MusubiSizes.radiusChip,
                        ),
                      ),
                      child: Text(
                        'Agotado',
                        style: MusubiType.style(
                          12,
                          weight: FontWeight.w800,
                          color: c.onBrand,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Text(
                formatPrice(product.priceCents),
                style: MusubiType.price.copyWith(
                  color: soldOut ? c.textSecondary : c.textPrimary,
                  decoration: soldOut ? TextDecoration.lineThrough : null,
                  decorationColor: c.textSecondary,
                  decorationThickness: soldOut ? 1.5 : null,
                ),
              ),
              Text(
                product.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: MusubiType.style(
                  13.5,
                  weight: FontWeight.w600,
                  line: 18,
                  color: soldOut ? c.textSecondary : c.textPrimary,
                ),
              ),
              if (product.sellerName != null)
                Text(
                  product.sellerName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MusubiType.style(
                    12,
                    weight: FontWeight.w600,
                    line: 18,
                    color: c.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
    return Stack(
      children: [
        Pressable(
          key: Key('favorite-card-${item.productId}'),
          onTap: onOpen,
          semanticLabel: product.title,
          pressScale: 0.97,
          builder: (context, _) => card,
        ),
        Positioned(
          top: 2,
          right: 2,
          child: SaveButton(
            key: Key('favorite-heart-${item.productId}'),
            productId: item.productId,
            onPressed: onRemove,
          ),
        ),
      ],
    );
  }
}

class _UnavailableTile extends StatelessWidget {
  const new({required this.item, required this.onRemove});

  final FavoriteItem item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Stack(
      children: [
        Container(
          height: 240,
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(MusubiSizes.radiusButton),
          ),
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                MusubiIcon(MusubiIcons.ban, size: 28, color: c.textSecondary),
                Text(
                  'Ya no está disponible',
                  textAlign: TextAlign.center,
                  style: MusubiType.style(
                    13.5,
                    weight: FontWeight.w700,
                    line: 18,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: SaveButton(
            key: Key('favorite-heart-${item.productId}'),
            productId: item.productId,
            onPressed: onRemove,
          ),
        ),
      ],
    );
  }
}
