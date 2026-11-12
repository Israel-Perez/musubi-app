import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/session/session_tokens.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/avatars.dart';
import 'package:musubi_app/core/widgets/feedback_views.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/core/widgets/skeleton.dart';
import 'package:musubi_app/core/widgets/top_bar.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/favorites_actions.dart';
import 'package:musubi_app/features/marketplace/presentation/home_cards.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';
import 'package:musubi_app/features/profile/domain/profile_models.dart';
import 'package:musubi_app/features/profile/presentation/profile_providers.dart';

enum _SellerTab { publications, reviews }

/// `Perfil-vendedor` (HU-05): cabecera publica, publicaciones activas y
/// opiniones. Se abre desde `Producto` y desde "Ver perfil" del chat.
///
/// NOTE (HU-20): "Mensaje" desde el perfil no se abre aqui; la conversacion
/// es de HU-20. NOTE (HU-27): promedio, calificaciones y opiniones.
class SellerProfileScreen extends ConsumerStatefulWidget {
  const new({required this.sellerId, super.key});

  final String sellerId;

  @override
  ConsumerState<SellerProfileScreen> createState() =>
      _SellerProfileScreenState();
}

class _SellerProfileScreenState extends ConsumerState<SellerProfileScreen> {
  _SellerTab _tab = _SellerTab.publications;

  /// Paginas siguientes de "Publicaciones" ("Ver más").
  final List<ProductSummary> _more = [];
  String? _moreCursor;
  bool _loadingMore = false;

  void _back() =>
      context.canPop() ? context.pop() : context.go(AppRoutes.profile);

  Future<void> _loadMore(String cursor) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _loadingMore = true);
    try {
      final page = await ref
          .read(catalogRepositoryProvider)
          .sellerListings(widget.sellerId, cursor: cursor);
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

  void _retryListings() {
    setState(() {
      _more.clear();
      _moreCursor = null;
    });
    ref.invalidate(sellerListingsProvider(widget.sellerId));
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(publicProfileProvider(widget.sellerId));
    return Scaffold(
      backgroundColor: context.musubi.background,
      body: switch (profile) {
        AsyncData(:final value) => _Loaded(
          sellerId: widget.sellerId,
          profile: value,
          tab: _tab,
          onTab: (tab) => setState(() => _tab = tab),
          more: _more,
          moreCursor: _moreCursor,
          loadingMore: _loadingMore,
          onLoadMore: _loadMore,
          onRetryListings: _retryListings,
          onBack: _back,
        ),
        AsyncError(:final error)
            when error is ApiFailure && error.code == 'profiles.not_found' =>
          _NotFound(onBack: _back),
        AsyncError(:final error) => _ProfileError(
          message: error is ApiFailure
              ? error.message
              : 'No pudimos cargar este perfil.',
          onRetry: () => ref.invalidate(publicProfileProvider(widget.sellerId)),
          onBack: _back,
        ),
        _ => _Loading(onBack: _back),
      },
    );
  }
}

class _Loaded extends ConsumerWidget {
  const new({
    required this.sellerId,
    required this.profile,
    required this.tab,
    required this.onTab,
    required this.more,
    required this.moreCursor,
    required this.loadingMore,
    required this.onLoadMore,
    required this.onRetryListings,
    required this.onBack,
  });

  final String sellerId;
  final PublicProfile profile;
  final _SellerTab tab;
  final ValueChanged<_SellerTab> onTab;
  final List<ProductSummary> more;
  final String? moreCursor;
  final bool loadingMore;
  final ValueChanged<String> onLoadMore;
  final VoidCallback onRetryListings;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listings = ref.watch(sellerListingsProvider(sellerId));
    final now = ref.watch(clockProvider)();
    final page = listings.value;
    final items = [...?page?.items, ...more];
    final next = moreCursor ?? page?.nextCursor;
    final hasMore = next != null && next.isNotEmpty;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: MusubiTopBar(title: profile.fullName, onBack: onBack),
          ),
          SliverToBoxAdapter(child: _Header(profile: profile)),
          SliverToBoxAdapter(
            child: _Tabs(
              tab: tab,
              publications: page?.total,
              reviews: profile.ratingCount,
              onSelect: onTab,
            ),
          ),
          if (tab == _SellerTab.reviews)
            SliverToBoxAdapter(
              child: SizedBox(height: 340, child: _Opinions(profile: profile)),
            )
          else
            ..._publications(
              context,
              ref,
              listings: listings,
              items: items,
              now: now,
              hasMore: hasMore,
              next: next,
            ),
          SliverToBoxAdapter(child: SizedBox(height: bottom + 24)),
        ],
      ),
    );
  }

  List<Widget> _publications(
    BuildContext context,
    WidgetRef ref, {
    required AsyncValue<ProductPage> listings,
    required List<ProductSummary> items,
    required DateTime now,
    required bool hasMore,
    required String? next,
  }) {
    if (listings.hasValue && items.isEmpty) {
      return [
        const SliverToBoxAdapter(
          child: SizedBox(
            height: 340,
            child: EmptyView(
              icon: MusubiIcons.tag,
              title: 'Sin publicaciones',
              message: 'Todavía no tiene publicaciones activas.',
            ),
          ),
        ),
      ];
    }
    if (listings.hasError && !listings.hasValue) {
      final error = listings.error;
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: ErrorView(
              message: error is ApiFailure
                  ? error.message
                  : 'No pudimos cargar las publicaciones.',
              onRetry: onRetryListings,
            ),
          ),
        ),
      ];
    }
    if (!listings.hasValue) {
      return const [
        SliverToBoxAdapter(
          child: SizedBox(
            height: 240,
            child: LoadingView(message: 'Cargando publicaciones…'),
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 20,
            crossAxisSpacing: 12,
            mainAxisExtent: 240,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final product = items[index];
            return RecentTile(
              product: product,
              now: now,
              showSeller: false,
              onSave: (product) =>
                  unawaited(toggleFavorite(context, ref, product)),
              onTap: () => unawaited(
                context.push(AppRoutes.product(product.id), extra: product),
              ),
            );
          }, childCount: items.length),
        ),
      ),
      if (hasMore)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: MusubiButton(
              label: loadingMore ? 'Cargando…' : 'Ver más',
              onPressed: loadingMore || next == null
                  ? null
                  : () => onLoadMore(next),
            ),
          ),
        ),
    ];
  }
}

/// Foto, nombre, campus, carrera y periodo, reputación y "En Musubi desde".
class _Header extends ConsumerWidget {
  const new({required this.profile});

  final PublicProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.musubi;
    // La unidad no viene en el perfil: sin `careers` solo se muestra el numero.
    final unit = ref.watch(careersProvider).value?.academicTerm;
    final career = profile.careerShortName;
    final term = profile.term;
    final subtitle = [
      profile.campusShortName,
      ?career,
      if (career != null && term != null) unit?.label(term) ?? '$termº',
    ].join(' · ');
    final rating = profile.ratingAvg;
    final sales = profile.sales;
    final palette = profile.id.codeUnits.fold(0, (sum, unit) => sum + unit) % 5;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Row(
            spacing: 14,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ProfileAvatar(
                    key: const Key('seller-avatar'),
                    initials: initialsOf(profile.fullName),
                    photoUrl: profile.photoUrl,
                    size: 72,
                    fontSize: 24,
                    palette: palette,
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    // El anillo es blanco tambien en modo noche, como en
                    // `Perfil`.
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFFFFF),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(child: VerifiedBadge(size: 23)),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 3,
                  children: [
                    Text(
                      profile.fullName,
                      key: const Key('seller-name'),
                      style: MusubiType.style(
                        20,
                        weight: FontWeight.w800,
                        line: 25,
                        em: -0.02,
                        color: c.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      key: const Key('seller-subtitle'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: MusubiType.style(
                        13,
                        weight: FontWeight.w600,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (rating != null) ...[
                MusubiIcon(
                  MusubiIcons.star,
                  size: 16,
                  fillColor: c.warning,
                  color: c.warning,
                  filled: true,
                ),
                Text(
                  rating.toStringAsFixed(1),
                  style: MusubiType.style(
                    14,
                    weight: FontWeight.w800,
                    color: c.textPrimary,
                  ),
                ),
                Text(
                  '· ${profile.ratingCount} calificaciones',
                  style: MusubiType.style(
                    12.5,
                    weight: FontWeight.w600,
                    color: c.textSecondary,
                  ),
                ),
              ] else
                Text(
                  'Sin calificaciones',
                  style: MusubiType.style(
                    13,
                    weight: FontWeight.w700,
                    color: c.textSecondary,
                  ),
                ),
              if (sales != null)
                Text(
                  '· ${sales == 1 ? '1 venta' : '$sales ventas'}',
                  style: MusubiType.style(
                    12.5,
                    weight: FontWeight.w600,
                    color: c.textSecondary,
                  ),
                ),
            ],
          ),
          Text(
            'En Musubi desde ${monthYear(profile.memberSince)}',
            key: const Key('seller-since'),
            style: MusubiType.style(
              12.5,
              weight: FontWeight.w600,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Publicaciones (N)" y "Opiniones (N)".
class _Tabs extends StatelessWidget {
  const new({
    required this.tab,
    required this.publications,
    required this.reviews,
    required this.onSelect,
  });

  final _SellerTab tab;
  final int? publications;
  final int reviews;
  final ValueChanged<_SellerTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    String label(_SellerTab value) => switch (value) {
      _SellerTab.publications =>
        publications == null
            ? 'Publicaciones'
            : 'Publicaciones ($publications)',
      _SellerTab.reviews => 'Opiniones ($reviews)',
    };
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      height: MusubiSizes.minTouch + 6,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(MusubiSizes.radiusField),
      ),
      child: Row(
        spacing: 3,
        children: [
          for (final value in _SellerTab.values)
            Expanded(
              child: Pressable(
                key: Key('seller-tab-${value.name}'),
                onTap: () => onSelect(value),
                selected: value == tab,
                semanticLabel: label(value),
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
                      label(value),
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

/// NOTE (HU-27): las opiniones llegan con HU-27/HU-45.
class _Opinions extends StatelessWidget {
  const new({required this.profile});

  final PublicProfile profile;

  @override
  Widget build(BuildContext context) => EmptyView(
    icon: MusubiIcons.star,
    title: 'Todavía no hay opiniones',
    message:
        'Cuando alguien califique a ${profile.fullName.split(' ').first}, '
        'aparecerán aquí.',
  );
}

class _Loading extends StatelessWidget {
  const new({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: Column(
      children: [
        MusubiTopBar(onBack: onBack),
        const Expanded(
          child: SkeletonShimmer(
            child: Padding(
              key: Key('seller-loading'),
              padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 14,
                children: [
                  Row(
                    spacing: 14,
                    children: [
                      SkeletonBox(width: 72, height: 72, radius: 36),
                      Expanded(
                        child: Column(
                          spacing: 8,
                          children: [
                            SkeletonBox(height: 20, width: 180),
                            SkeletonBox(height: 14, width: 140),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SkeletonBox(height: 14, width: 220),
                  SkeletonBox(height: 54, radius: 14),
                  Row(
                    spacing: 12,
                    children: [
                      Expanded(child: SkeletonBox(height: 210, radius: 16)),
                      Expanded(child: SkeletonBox(height: 210, radius: 16)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _ProfileError extends StatelessWidget {
  const new({
    required this.message,
    required this.onRetry,
    required this.onBack,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(
      children: [
        MusubiTopBar(onBack: onBack),
        Expanded(
          child: ErrorView(message: message, onRetry: onRetry),
        ),
      ],
    ),
  );
}

class _NotFound extends StatelessWidget {
  const new({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(
      children: [
        MusubiTopBar(onBack: onBack),
        Expanded(
          child: EmptyView(
            icon: MusubiIcons.users,
            title: 'No encontramos ese perfil',
            message: 'Puede que ya no esté disponible o no sea de tu campus.',
            actionLabel: 'Regresar',
            onAction: onBack,
          ),
        ),
      ],
    ),
  );
}
