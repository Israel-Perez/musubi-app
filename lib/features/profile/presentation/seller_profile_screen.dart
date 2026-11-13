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
import 'package:musubi_app/features/reputation/domain/reputation_models.dart';
import 'package:musubi_app/features/reputation/presentation/reputation_providers.dart';

enum _SellerTab { publications, reviews }

/// Desde donde se abrio `Perfil-vendedor`: decide a que conversacion lleva
/// "Mensaje" (como `mensajeV` de la maqueta).
@immutable
class SellerProfileOrigin {
  /// Desde el detalle (`Producto`): "Mensaje" abre el chat de esa publicacion.
  const new product(ProductSummary this.product) : fromChat = false;

  /// Desde "Ver perfil" del chat: "Mensaje" regresa a esa conversacion.
  const new chat() : product = null, fromChat = true;

  final ProductSummary? product;
  final bool fromChat;
}

/// `Perfil-vendedor` (HU-05): cabecera publica, "Seguir" y "Mensaje", cifras,
/// publicaciones activas y opiniones. Se abre desde `Producto` y desde
/// "Ver perfil" del chat.
///
/// Promedio, calificaciones, "Opiniones" y "A tiempo" salen de HU-27/HU-45.
/// "Seguir" y "Compartir" avisan que llegan pronto (la API no tiene
/// seguidores ni enlaces publicos); "Responde en" queda fuera como en HU-11.
class SellerProfileScreen extends ConsumerStatefulWidget {
  const new({required this.sellerId, super.key, this.origin});

  final String sellerId;
  final SellerProfileOrigin? origin;

  @override
  ConsumerState<SellerProfileScreen> createState() =>
      _SellerProfileScreenState();
}

class _SellerProfileScreenState extends ConsumerState<SellerProfileScreen> {
  _SellerTab _tab = _SellerTab.publications;

  /// Paginas siguientes de "Opiniones" ("Ver más", HU-27).
  final List<Opinion> _moreOpinions = [];
  String? _opinionsCursor;
  bool _loadingOpinions = false;

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

  Future<void> _loadMoreOpinions(String cursor) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _loadingOpinions = true);
    try {
      final page = await ref
          .read(reputationRepositoryProvider)
          .opinions(widget.sellerId, cursor: cursor);
      if (!mounted) return;
      setState(() {
        _moreOpinions.addAll(page.items);
        _opinionsCursor = page.nextCursor ?? '';
        _loadingOpinions = false;
      });
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() => _loadingOpinions = false);
      showMusubiSnack(
        messenger,
        failure.message,
        icon: MusubiIcons.circleAlert,
        tone: SnackTone.warn,
      );
    }
  }

  void _retryOpinions() {
    setState(() {
      _moreOpinions.clear();
      _opinionsCursor = null;
    });
    ref.invalidate(opinionsProvider(widget.sellerId));
  }

  void _retryListings() {
    setState(() {
      _more.clear();
      _moreCursor = null;
    });
    ref.invalidate(sellerListingsProvider(widget.sellerId));
  }

  void _soon(String what) => showMusubiSnack(
    ScaffoldMessenger.of(context),
    '$what llega muy pronto.',
    icon: MusubiIcons.clock,
    tone: SnackTone.info,
  );

  /// "Mensaje" (`mensajeV` de la maqueta): desde el chat regresa a esa
  /// conversacion; si no, abre la de la publicacion de origen o la de su
  /// primera publicacion activa (el chat es por publicacion, HU-20).
  void _message(PublicProfile profile, List<ProductSummary> items) {
    final origin = widget.origin;
    if (origin != null && origin.fromChat) {
      _back();
      return;
    }
    final product = origin?.product ?? (items.isEmpty ? null : items.first);
    if (product == null) {
      showMusubiSnack(
        ScaffoldMessenger.of(context),
        '${profile.firstName} no tiene publicaciones activas para escribirle.',
        icon: MusubiIcons.circleAlert,
        tone: SnackTone.info,
      );
      return;
    }
    unawaited(context.push(AppRoutes.chat, extra: product));
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
          moreOpinions: _moreOpinions,
          opinionsCursor: _opinionsCursor,
          loadingOpinions: _loadingOpinions,
          onLoadMoreOpinions: _loadMoreOpinions,
          onRetryOpinions: _retryOpinions,
          onShare: () => _soon('Compartir'),
          onFollow: () => _soon('Seguir a ${value.firstName}'),
          onMessage: (items) => _message(value, items),
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
    required this.onShare,
    required this.onFollow,
    required this.onMessage,
    required this.moreOpinions,
    required this.opinionsCursor,
    required this.loadingOpinions,
    required this.onLoadMoreOpinions,
    required this.onRetryOpinions,
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
  final VoidCallback onShare;
  final VoidCallback onFollow;
  final ValueChanged<List<ProductSummary>> onMessage;
  final List<Opinion> moreOpinions;
  final String? opinionsCursor;
  final bool loadingOpinions;
  final ValueChanged<String> onLoadMoreOpinions;
  final VoidCallback onRetryOpinions;

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
            child: _TopBar(onBack: onBack, onShare: onShare),
          ),
          SliverToBoxAdapter(child: _Header(profile: profile)),
          SliverToBoxAdapter(
            child: _Actions(
              onFollow: onFollow,
              onMessage: () => onMessage(items),
            ),
          ),
          SliverToBoxAdapter(
            child: _Stats(
              sales: profile.sales,
              publications: page?.total,
              onTime: profile.onTime,
            ),
          ),
          SliverToBoxAdapter(
            child: _Tabs(
              tab: tab,
              publications: page?.total,
              reviews: profile.ratingCount,
              onSelect: onTab,
            ),
          ),
          if (tab == _SellerTab.reviews)
            ..._opinions(context, ref)
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

  /// "Lo que dicen de Valeria" (HU-27): tarjetas, "Ver más", vacio y error.
  List<Widget> _opinions(BuildContext context, WidgetRef ref) {
    final c = context.musubi;
    final opinions = ref.watch(opinionsProvider(sellerId));
    final items = [...?opinions.value?.items, ...moreOpinions];
    final next = opinionsCursor ?? opinions.value?.nextCursor;
    if (opinions.hasError && !opinions.hasValue) {
      final error = opinions.error;
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: ErrorView(
              message: error is ApiFailure
                  ? error.message
                  : 'No pudimos cargar las opiniones.',
              onRetry: onRetryOpinions,
            ),
          ),
        ),
      ];
    }
    if (!opinions.hasValue) {
      return const [
        SliverToBoxAdapter(
          child: SizedBox(
            height: 240,
            child: LoadingView(message: 'Cargando opiniones…'),
          ),
        ),
      ];
    }
    if (items.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: SizedBox(height: 340, child: _Opinions(profile: profile)),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        sliver: SliverList.list(
          children: [
            Text(
              'Lo que dicen de ${profile.firstName}',
              style: MusubiType.style(
                16,
                weight: FontWeight.w800,
                color: c.textPrimary,
              ),
            ),
            for (final opinion in items)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: _OpinionCard(opinion: opinion),
              ),
            if (next != null && next.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: MusubiButton(
                  key: const Key('seller-opinions-more'),
                  label: loadingOpinions ? 'Cargando…' : 'Ver más',
                  onPressed: loadingOpinions
                      ? null
                      : () => onLoadMoreOpinions(next),
                ),
              ),
          ],
        ),
      ),
    ];
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

/// "Regresar" y "Compartir" (`header` de `Perfil-vendedor`: 44 de alto con
/// 8 a los lados).
class _TopBar extends StatelessWidget {
  const new({required this.onBack, required this.onShare});

  final VoidCallback onBack;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    Widget button(
      String label,
      MusubiIconData icon,
      double size,
      VoidCallback onTap,
    ) => Pressable(
      key: Key('seller-${label.toLowerCase()}'),
      onTap: onTap,
      semanticLabel: label,
      builder: (context, _) => SizedBox.square(
        dimension: MusubiSizes.minTouch,
        child: Center(
          child: MusubiIcon(
            icon,
            size: size,
            strokeWidth: 1.9,
            color: c.textPrimary,
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        height: MusubiSizes.minTouch,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            button('Regresar', MusubiIcons.chevronLeft, 24, onBack),
            button('Compartir', MusubiIcons.share, 21, onShare),
          ],
        ),
      ),
    );
  }
}

/// Foto con "Verificada", nombre, carrera y periodo, reputación y
/// "En Musubi desde", centrados como en la maqueta.
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
    // Como la maqueta: "Arquitectura · 8º semestre". Si oculta la carrera
    // (HU-04), queda el campus para que la linea no se vacie.
    final subtitle = career == null
        ? profile.campusShortName
        : [career, if (term != null) unit?.label(term) ?? '$termº'].join(' · ');
    final rating = profile.ratingAvg;
    final palette = profile.id.codeUnits.fold(0, (sum, unit) => sum + unit) % 5;
    final secondary = MusubiType.style(
      14,
      weight: FontWeight.w600,
      color: c.textSecondary,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ProfileAvatar(
                key: const Key('seller-avatar'),
                initials: initialsOf(profile.fullName),
                photoUrl: profile.photoUrl,
                size: 84,
                fontSize: 26,
                palette: palette,
              ),
              const Positioned(
                right: -2,
                bottom: 0,
                child: VerifiedBadge(size: 26),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              profile.fullName,
              key: const Key('seller-name'),
              textAlign: TextAlign.center,
              style: MusubiType.style(
                24,
                weight: FontWeight.w800,
                line: 30,
                em: -0.025,
                color: c.textPrimary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              subtitle,
              key: const Key('seller-subtitle'),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: secondary,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              key: const Key('seller-rating'),
              mainAxisSize: MainAxisSize.min,
              spacing: 5,
              children: [
                if (rating != null) ...[
                  MusubiIcon(
                    MusubiIcons.star,
                    size: 16,
                    color: c.warning,
                    fillColor: c.warning,
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
                    profile.ratingCount == 1
                        ? '1 calificación'
                        : '${profile.ratingCount} calificaciones',
                    style: secondary,
                  ),
                ] else
                  Text('Sin calificaciones', style: secondary),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
              key: const Key('seller-since'),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
              ),
              child: Text(
                'En Musubi desde ${monthYear(profile.memberSince)}',
                style: MusubiType.style(
                  12.5,
                  weight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Seguir" (borde) y "Mensaje" (rojo), en dos columnas de 48 de alto.
class _Actions extends StatelessWidget {
  const new({required this.onFollow, required this.onMessage});

  final VoidCallback onFollow;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    Widget action({
      required String label,
      required MusubiIconData icon,
      required VoidCallback onTap,
      required bool primary,
    }) => Expanded(
      child: Pressable(
        key: Key('seller-${label.toLowerCase()}'),
        onTap: onTap,
        semanticLabel: label,
        builder: (context, pressed) {
          final ink = primary ? c.onBrand : c.textPrimary;
          final background = switch ((primary, pressed)) {
            (true, false) => c.brand,
            (true, true) => c.brandPressed,
            (false, true) => c.surface,
            (false, false) => null,
          };
          return Container(
            height: 48,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(14),
              border: primary ? null : Border.all(color: c.border, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 8,
              children: [
                MusubiIcon(icon, size: 19, strokeWidth: 1.9, color: ink),
                Text(
                  label,
                  style: MusubiType.style(
                    15,
                    weight: FontWeight.w800,
                    color: ink,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Row(
        spacing: 10,
        children: [
          action(
            label: 'Seguir',
            icon: MusubiIcons.userPlus,
            onTap: onFollow,
            primary: false,
          ),
          action(
            label: 'Mensaje',
            icon: MusubiIcons.messageCircle,
            onTap: onMessage,
            primary: true,
          ),
        ],
      ),
    );
  }
}

/// Ventas, publicaciones y "A tiempo" en un recuadro de tres columnas.
/// Sin el dato (ventas ocultas, publicaciones cargando, sin calificaciones)
/// va "—", como en `Perfil`. "A tiempo" es el porcentaje con "Puntual"
/// (HU-27).
class _Stats extends StatelessWidget {
  const new({
    required this.sales,
    required this.publications,
    required this.onTime,
  });

  final int? sales;
  final int? publications;
  final int? onTime;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    Widget cell(String key, String value, String label, {bool last = false}) =>
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              border: last ? null : Border(right: BorderSide(color: c.border)),
            ),
            child: Column(
              spacing: 2,
              children: [
                Text(
                  value,
                  key: Key('seller-stat-$key'),
                  style: MusubiType.style(
                    18,
                    weight: FontWeight.w800,
                    color: c.textPrimary,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MusubiType.style(
                    12,
                    weight: FontWeight.w700,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
    return Container(
      key: const Key('seller-stats'),
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            cell('sales', sales == null ? '—' : '$sales', 'Ventas'),
            cell(
              'publications',
              publications == null ? '—' : '$publications',
              'Publicaciones',
            ),
            cell(
              'on-time',
              onTime == null ? '—' : '$onTime%',
              'A tiempo',
              last: true,
            ),
          ],
        ),
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
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      height: MusubiSizes.minTouch,
      // Sin relleno vertical: el toque cubre los 44 (RNF-27) y la pastilla
      // de 38 queda a 3 del borde, como en la maqueta.
      padding: const EdgeInsets.symmetric(horizontal: 3),
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
                builder: (context, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
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

/// "Opiniones" sin calificaciones todavia (RN-26).
class _Opinions extends StatelessWidget {
  const new({required this.profile});

  final PublicProfile profile;

  @override
  Widget build(BuildContext context) => EmptyView(
    icon: MusubiIcons.star,
    title: 'Todavía no hay opiniones',
    message:
        'Cuando alguien califique a ${profile.firstName}, '
        'aparecerán aquí.',
  );
}

/// Una opinion (maqueta: `article` gris de radio 18): estrellas y fecha,
/// el comentario y "Luis M. · Puntual".
class _OpinionCard extends StatelessWidget {
  const new({required this.opinion});

  final Opinion opinion;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final comment = opinion.comment;
    final tag = opinion.tags.isEmpty ? null : opinion.tags.first.label;
    return Semantics(
      container: true,
      label: '${opinion.stars} de 5 estrellas',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ExcludeSemantics(
                  child: Row(
                    spacing: 1,
                    children: [
                      for (var n = 1; n <= 5; n++)
                        MusubiIcon(
                          MusubiIcons.star,
                          size: 14,
                          filled: true,
                          fillColor: n <= opinion.stars ? c.warning : c.border,
                          color: n <= opinion.stars ? c.warning : c.border,
                        ),
                    ],
                  ),
                ),
                Text(
                  dayMonth(opinion.createdAt.toLocal()),
                  style: MusubiType.style(
                    12,
                    weight: FontWeight.w600,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
            if (comment != null)
              Text(
                comment,
                style: MusubiType.style(14, line: 20, color: c.textPrimary),
              ),
            Text(
              tag == null ? opinion.raterName : '${opinion.raterName} · $tag',
              style: MusubiType.style(
                12.5,
                weight: FontWeight.w700,
                color: c.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
