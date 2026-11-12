import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/core/session/session_tokens.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/avatars.dart';
import 'package:musubi_app/core/widgets/feedback_views.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/features/auth/presentation/account_gate.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/domain/product_detail.dart';
import 'package:musubi_app/features/marketplace/presentation/favorites_actions.dart';
import 'package:musubi_app/features/marketplace/presentation/favorites_providers.dart';
import 'package:musubi_app/features/marketplace/presentation/home_cards.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';
import 'package:musubi_app/features/profile/domain/profile_models.dart';
import 'package:musubi_app/features/profile/presentation/profile_providers.dart';
import 'package:musubi_app/features/profile/presentation/seller_profile_screen.dart';

/// Detalle de una publicacion (HU-11). Publico, como la vitrina (HU-48).
final FutureProviderFamily<ProductDetail, String> productDetailProvider =
    FutureProvider.autoDispose.family<ProductDetail, String>(
      (ref, id) => ref.watch(catalogRepositoryProvider).product(id),
      retry: (_, _) => null,
    );

/// `ProductDetail` → tarjeta que usa el estado de favoritos (HU-53).
ProductSummary _summaryOf(ProductDetail detail) => ProductSummary(
  id: detail.id,
  title: detail.title,
  priceCents: detail.priceCents,
  stock: detail.stock,
  photoUrl: detail.photoUrls.isEmpty ? null : detail.photoUrls.first,
  condition: detail.conditionName,
  sellerName: detail.sellerName,
  publishedAt: detail.publishedAt,
);

/// `Producto` y `Producto-visitante` (HU-11): fotos, precio, estado, piezas,
/// descripcion, quien vende y "Mensaje" / "Comprar" hacia el chat (HU-20).
///
/// NOTE (HU-52): "Apartalo 24 h" y "Apartar".
/// NOTE (HU-51): "Compara antes de comprar" y "Ver parecidos".
/// NOTE (HU-53): "Guardar" y "Avisame".
/// NOTE (HU-23): "Comprar" abre el chat (como la maqueta) hasta los pedidos.
class ProductScreen extends ConsumerStatefulWidget {
  const new({required this.productId, super.key, this.preview});

  final String productId;

  /// Tarjeta de Inicio para mostrar mientras carga.
  final ProductSummary? preview;

  @override
  ConsumerState<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends ConsumerState<ProductScreen> {
  final _pages = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _soon(String what) => showMusubiSnack(
    ScaffoldMessenger.of(context),
    '$what llega muy pronto.',
    icon: MusubiIcons.clock,
    tone: SnackTone.info,
  );

  void _gate(AccountGateMotive motive) => unawaited(
    showAccountGate(
      context,
      motive: motive,
      returnTo: AppRoutes.product(widget.productId),
    ),
  );

  /// HU-53: el corazon del detalle usa el mismo estado global que las tarjetas.
  void _toggle(ProductDetail detail) =>
      unawaited(toggleFavorite(context, ref, _summaryOf(detail)));

  /// "Mensaje" y "Comprar": el chat con quien vende (HU-20).
  void _chat(
    ProductDetail detail, {
    required bool signedIn,
    required bool buy,
  }) {
    if (!signedIn) {
      _gate(buy ? AccountGateMotive.buy : AccountGateMotive.chat);
      return;
    }
    unawaited(
      context.push(
        AppRoutes.chat,
        extra: ProductSummary(
          id: detail.id,
          title: detail.title,
          priceCents: detail.priceCents,
          stock: detail.stock,
          photoUrl: detail.photoUrls.isEmpty ? null : detail.photoUrls.first,
          condition: detail.conditionName,
          sellerName: detail.sellerName,
          publishedAt: detail.publishedAt,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final session = ref.watch(sessionControllerProvider);
    final signedIn = session is SignedIn;
    final myId = session is SignedIn ? session.tokens.userId : null;
    final campus = session is SignedIn
        ? session.tokens.profile?.campus ?? 'UTTT'
        : 'UTTT';
    final detail = ref.watch(productDetailProvider(widget.productId));
    final saved =
        ref.watch(favoritesProvider).value?.contains(widget.productId) ?? false;

    return Scaffold(
      backgroundColor: c.background,
      body: switch (detail) {
        AsyncData(:final value) => _Loaded(
          detail: value,
          campus: campus,
          signedIn: signedIn,
          mine: myId != null && value.sellerId == myId,
          saved: saved,
          now: ref.watch(clockProvider)(),
          pages: _pages,
          page: _page,
          onPage: (page) => setState(() => _page = page),
          onBack: () => context.pop(),
          onShare: () => _soon('Compartir'),
          onSave: () =>
              signedIn ? _toggle(value) : _gate(AccountGateMotive.save),
          onReserve: () =>
              signedIn ? _soon('Apartar') : _gate(AccountGateMotive.buy),
          onNotify: () =>
              signedIn ? _soon('El aviso') : _gate(AccountGateMotive.save),
          onSimilar: () => _soon('Ver parecidos'),
          onSeller: () {
            final sellerId = value.sellerId;
            if (sellerId == null) return;
            unawaited(
              myId != null && sellerId == myId
                  ? context.push(AppRoutes.profile)
                  : context.push(
                      AppRoutes.sellerProfile(sellerId),
                      extra: SellerProfileOrigin.product(_summaryOf(value)),
                    ),
            );
          },
          onMessage: () => _chat(value, signedIn: signedIn, buy: false),
          onBuy: () => _chat(value, signedIn: signedIn, buy: true),
          onMine: () => unawaited(context.push(AppRoutes.myProducts)),
        ),
        AsyncError(:final error) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(MusubiSizes.space6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: MusubiSizes.space4,
              children: [
                InlineMessage(
                  message: error is ApiFailure
                      ? error.message
                      : 'No pudimos abrir esta publicación.',
                  kind: InlineMessageKind.warning,
                ),
                Pressable(
                  onTap: () => context.pop(),
                  semanticLabel: 'Regresar',
                  builder: (context, _) => SizedBox(
                    height: MusubiSizes.minTouch,
                    child: Center(
                      child: Text(
                        'Regresar',
                        style: MusubiType.style(
                          14.5,
                          weight: FontWeight.w800,
                          color: c.brandStrongText,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _ => _Preview(preview: widget.preview, onBack: () => context.pop()),
      },
    );
  }
}

/// Mientras carga: la foto y el precio de la tarjeta de Inicio.
class _Preview extends StatelessWidget {
  const new({required this.preview, required this.onBack});

  final ProductSummary? preview;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Stack(
      children: [
        SizedBox(
          height: 360,
          width: double.infinity,
          child: ColoredBox(
            color: c.surface,
            child: ProductPhoto(url: preview?.photoUrl),
          ),
        ),
        Positioned(
          left: 12,
          top: MediaQuery.paddingOf(context).top - 4,
          child: _RoundButton(
            icon: MusubiIcons.chevronLeft,
            label: 'Regresar',
            onTap: onBack,
          ),
        ),
      ],
    );
  }
}

class _Loaded extends ConsumerWidget {
  const new({
    required this.detail,
    required this.campus,
    required this.signedIn,
    required this.mine,
    required this.saved,
    required this.now,
    required this.pages,
    required this.page,
    required this.onPage,
    required this.onBack,
    required this.onShare,
    required this.onSave,
    required this.onReserve,
    required this.onNotify,
    required this.onSimilar,
    required this.onSeller,
    required this.onMessage,
    required this.onBuy,
    required this.onMine,
  });

  final ProductDetail detail;
  final String campus;
  final bool signedIn;
  final bool mine;
  final bool saved;
  final DateTime now;
  final PageController pages;
  final int page;
  final ValueChanged<int> onPage;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback onSave;
  final VoidCallback onReserve;
  final VoidCallback onNotify;
  final VoidCallback onSimilar;
  final VoidCallback onSeller;
  final VoidCallback onMessage;
  final VoidCallback onBuy;
  final VoidCallback onMine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.musubi;
    final soldOut = detail.soldOut;
    final sellerId = detail.sellerId;
    final profile = sellerId == null
        ? null
        : ref.watch(publicProfileProvider(sellerId)).value;
    // Como la maqueta: "Último" y "Quedan 2" cuando quedan pocas.
    final stock = switch (detail.stock) {
      _ when soldOut => 'Agotado',
      1 => 'Último',
      2 => 'Quedan 2',
      final n => '$n piezas',
    };
    final lowStock = !soldOut && detail.stock <= 2;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Gallery(
                  photos: detail.photoUrls,
                  soldOut: soldOut,
                  campus: campus,
                  saved: saved,
                  controller: pages,
                  page: page,
                  onPage: onPage,
                  onBack: onBack,
                  onShare: onShare,
                  onSave: onSave,
                ),
                Transform.translate(
                  offset: const Offset(0, -22),
                  child: Container(
                    decoration: BoxDecoration(
                      color: c.background,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 14,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          spacing: 12,
                          children: [
                            Text(
                              formatPrice(detail.priceCents),
                              style:
                                  MusubiType.style(
                                    30,
                                    weight: FontWeight.w800,
                                    line: 36,
                                    em: -0.03,
                                    tabular: true,
                                    color: soldOut
                                        ? c.textSecondary
                                        : c.textPrimary,
                                  ).copyWith(
                                    decoration: soldOut
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                            ),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: c.surface,
                                  borderRadius: BorderRadius.circular(
                                    MusubiSizes.radiusChip,
                                  ),
                                ),
                                child: Text(
                                  detail.conditionLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                        Transform.translate(
                          offset: const Offset(0, -6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 4,
                            children: [
                              Semantics(
                                header: true,
                                child: Text(
                                  detail.title,
                                  style: MusubiType.style(
                                    20,
                                    weight: FontWeight.w800,
                                    line: 26,
                                    em: -0.02,
                                    color: c.textPrimary,
                                  ),
                                ),
                              ),
                              Text(
                                '${detail.categoryName} · Publicado '
                                '${timeAgo(detail.publishedAt, now)}',
                                style: MusubiType.style(
                                  13,
                                  color: c.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          spacing: 8,
                          children: [
                            _Tile(label: 'Estado', value: detail.conditionName),
                            _Tile(
                              label: 'Disponibles',
                              value: stock,
                              background: lowStock ? c.warningSoft : null,
                              ink: soldOut
                                  ? c.textSecondary
                                  : lowStock
                                  ? c.warningText
                                  : null,
                            ),
                            const _Tile(label: 'Entrega', value: 'Campus'),
                          ],
                        ),
                        if (!soldOut && !mine) _ReserveBanner(onTap: onReserve),
                        if (detail.description.isNotEmpty)
                          Text(
                            detail.description,
                            style: MusubiType.style(
                              14.5,
                              line: 22,
                              color: c.textPrimary,
                            ),
                          ),
                        _SellerCard(
                          name: profile?.fullName ?? detail.sellerName,
                          profile: profile,
                          paletteSeed: sellerId ?? detail.id,
                          onTap: signedIn
                              ? onSeller
                              : () => showAccountGate(
                                  context,
                                  motive: AccountGateMotive.profile,
                                  returnTo: AppRoutes.product(detail.id),
                                ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _ActionBar(
          soldOut: soldOut,
          mine: mine,
          onMessage: onMessage,
          onReserve: onReserve,
          onBuy: onBuy,
          onNotify: onNotify,
          onSimilar: onSimilar,
          onMine: onMine,
        ),
      ],
    );
  }
}

/// Carrusel de 360 con regresar, campus, compartir y guardar, los puntos y
/// "1 / 4". Agotado: "Ya no esta disponible" al centro.
class _Gallery extends StatelessWidget {
  const new({
    required this.photos,
    required this.soldOut,
    required this.campus,
    required this.saved,
    required this.controller,
    required this.page,
    required this.onPage,
    required this.onBack,
    required this.onShare,
    required this.onSave,
  });

  final List<String> photos;
  final bool soldOut;
  final String campus;
  final bool saved;
  final PageController controller;
  final int page;
  final ValueChanged<int> onPage;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final count = photos.isEmpty ? 1 : photos.length;
    return SizedBox(
      height: 360,
      child: ColoredBox(
        color: c.surface,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Semantics(
              label: 'Fotos del producto',
              child: PageView.builder(
                controller: controller,
                itemCount: count,
                onPageChanged: onPage,
                itemBuilder: (context, index) => ProductPhoto(
                  url: photos.isEmpty ? null : photos[index],
                  soldOut: soldOut,
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              top: MediaQuery.paddingOf(context).top - 4,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    spacing: 8,
                    children: [
                      _RoundButton(
                        icon: MusubiIcons.chevronLeft,
                        label: 'Regresar',
                        onTap: onBack,
                      ),
                      _CampusPill(campus: campus),
                    ],
                  ),
                  Row(
                    spacing: 10,
                    children: [
                      _RoundButton(
                        icon: MusubiIcons.share,
                        label: 'Compartir',
                        onTap: onShare,
                        iconSize: 20,
                      ),
                      _RoundButton(
                        icon: MusubiIcons.heart,
                        label: saved ? 'Quitar de favoritos' : 'Guardar',
                        onTap: onSave,
                        iconSize: 20,
                        active: saved,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (count > 1)
              Positioned(
                left: 0,
                right: 0,
                bottom: 36,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 6,
                  children: [
                    for (var i = 0; i < count; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: i == page ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i == page
                              ? c.inverse
                              : c.inverse.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                  ],
                ),
              ),
            Positioned(
              right: 16,
              bottom: 32,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: c.inverse.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
                ),
                child: Text(
                  '${page + 1} / $count',
                  style: MusubiType.style(
                    12,
                    weight: FontWeight.w700,
                    color: c.onBrand,
                  ),
                ),
              ),
            ),
            if (soldOut)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: c.inverse,
                    borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x401C1C1E),
                        offset: Offset(0, 10),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 8,
                    children: [
                      MusubiIcon(
                        MusubiIcons.ban,
                        size: 18,
                        strokeWidth: 2.2,
                        color: c.onBrand,
                      ),
                      Text(
                        'Ya no está disponible',
                        style: MusubiType.style(
                          15,
                          weight: FontWeight.w800,
                          line: 20,
                          color: c.onBrand,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Boton redondo blanco (.94) con sombra sobre la foto.
class _RoundButton extends StatelessWidget {
  const new({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconSize = 22,
    this.active = false,
  });

  final MusubiIconData icon;
  final String label;
  final VoidCallback onTap;
  final double iconSize;

  /// Corazon guardado: relleno y en color de marca.
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      builder: (context, _) => Container(
        width: MusubiSizes.minTouch,
        height: MusubiSizes.minTouch,
        decoration: const BoxDecoration(
          color: Color(0xF0FFFFFF),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x1F1C1C1E),
              offset: Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: MusubiIcon(
          icon,
          size: iconSize,
          color: active ? c.brand : const Color(0xFF1C1C1E),
          fillColor: active ? c.brand : null,
          filled: active,
        ),
      ),
    );
  }
}

/// "UTTT" con la insignia, sobre la foto.
class _CampusPill extends StatelessWidget {
  const new({required this.campus});

  final String campus;

  @override
  Widget build(BuildContext context) => Container(
    height: MusubiSizes.minTouch,
    padding: const EdgeInsets.only(left: 9, right: 12),
    decoration: BoxDecoration(
      color: const Color(0xF0FFFFFF),
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1F1C1C1E),
          offset: Offset(0, 2),
          blurRadius: 8,
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: context.musubi.brand,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const MusubiIcon(
            MusubiIcons.graduationCap,
            size: 15,
            strokeWidth: 2.2,
            color: Color(0xFFFFFFFF),
          ),
        ),
        Semantics(
          label: 'Campus $campus',
          excludeSemantics: true,
          child: Text(
            campus,
            style: MusubiType.style(
              13.5,
              weight: FontWeight.w800,
              line: 16,
              em: 0.02,
              color: const Color(0xFF1C1C1E),
            ),
          ),
        ),
        const VerifiedBadge(size: 15),
      ],
    ),
  );
}

class _Tile extends StatelessWidget {
  const new({
    required this.label,
    required this.value,
    this.background,
    this.ink,
  });

  final String label;
  final String value;
  final Color? background;
  final Color? ink;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: background ?? c.surface,
          borderRadius: BorderRadius.circular(MusubiSizes.radiusField),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 2,
          children: [
            Text(
              label,
              style: MusubiType.style(
                11.5,
                weight: FontWeight.w600,
                color: ink ?? c.textSecondary,
              ),
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: MusubiType.style(
                14,
                weight: FontWeight.w800,
                color: ink ?? c.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Apartalo 24 h sin pagar" (HU-52).
class _ReserveBanner extends StatelessWidget {
  const new({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Pressable(
      onTap: onTap,
      semanticLabel: 'Apártalo 24 h sin pagar',
      builder: (context, pressed) => Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
        decoration: BoxDecoration(
          color: c.brandSoft,
          borderRadius: BorderRadius.circular(MusubiSizes.radiusButton),
        ),
        child: Row(
          spacing: 12,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.brand,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: MusubiIcon(MusubiIcons.qrCode, size: 20, color: c.onBrand),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 1,
                children: [
                  Text(
                    'Apártalo 24 h sin pagar',
                    style: MusubiType.style(
                      14.5,
                      weight: FontWeight.w800,
                      line: 19,
                      color: c.textPrimary,
                    ),
                  ),
                  Text(
                    'Lo recoges con tu QR o código',
                    style: MusubiType.style(
                      12.5,
                      weight: FontWeight.w600,
                      line: 17,
                      color: c.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox.square(
              dimension: MusubiSizes.minTouch,
              child: Center(
                child: MusubiIcon(
                  MusubiIcons.chevronRight,
                  size: 20,
                  strokeWidth: 2.2,
                  color: c.brandStrongText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quien vende: iniciales, nombre verificado, calificacion, ventas y carrera.
/// Sin sesion la API no lo dice (RNF-05): invita a crear la cuenta.
class _SellerCard extends StatelessWidget {
  const new({
    required this.name,
    required this.profile,
    required this.paletteSeed,
    required this.onTap,
  });

  final String? name;
  final PublicProfile? profile;
  final String paletteSeed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final known = name != null;
    final rating = profile?.ratingAvg;
    final details = [
      if (profile case PublicProfile(:final sales?)) ...[
        if (sales == 1) '1 venta' else '$sales ventas',
      ],
      ?profile?.careerShortName,
    ];
    return Pressable(
      onTap: onTap,
      semanticLabel: known
          ? 'Ver perfil de $name'
          : 'Crea tu cuenta para ver quién lo vende',
      builder: (context, pressed) => Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
        decoration: BoxDecoration(
          color: pressed ? c.surface : null,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          spacing: 12,
          children: [
            InitialsAvatar(
              initials: known ? initialsOf(name!) : '?',
              size: 46,
              fontSize: 15,
              palette: paletteSeed.codeUnits.fold(0, (a, b) => a + b) % 5,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Row(
                    spacing: 5,
                    children: [
                      Flexible(
                        child: Text(
                          known ? name! : 'Estudiante verificado',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: MusubiType.style(
                            15,
                            weight: FontWeight.w800,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                      const VerifiedBadge(size: 16),
                    ],
                  ),
                  if (known)
                    Text.rich(
                      TextSpan(
                        children: [
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: MusubiIcon(
                                MusubiIcons.star,
                                size: 13,
                                fillColor: c.warning,
                                color: c.warning,
                                filled: true,
                              ),
                            ),
                          ),
                          if (rating != null) ...[
                            TextSpan(
                              text: rating.toStringAsFixed(1),
                              style: TextStyle(
                                color: c.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            TextSpan(text: ' (${profile!.ratingCount})'),
                          ] else
                            const TextSpan(text: 'Sin calificaciones'),
                          for (final d in details) TextSpan(text: ' · $d'),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MusubiType.style(
                        12.5,
                        weight: FontWeight.w600,
                        color: c.textSecondary,
                      ),
                    )
                  else
                    Text(
                      'Crea tu cuenta para ver quién lo vende',
                      style: MusubiType.style(
                        12.5,
                        weight: FontWeight.w600,
                        color: c.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox.square(
              dimension: MusubiSizes.minTouch,
              child: Center(
                child: MusubiIcon(
                  MusubiIcons.chevronRight,
                  size: 20,
                  color: c.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Barra fija: "Mensaje", "Apartar" y "Comprar"; agotado: "Avisame" y "Ver
/// parecidos"; la mia: "Ver mis productos".
class _ActionBar extends StatelessWidget {
  const new({
    required this.soldOut,
    required this.mine,
    required this.onMessage,
    required this.onReserve,
    required this.onBuy,
    required this.onNotify,
    required this.onSimilar,
    required this.onMine,
  });

  final bool soldOut;
  final bool mine;
  final VoidCallback onMessage;
  final VoidCallback onReserve;
  final VoidCallback onBuy;
  final VoidCallback onNotify;
  final VoidCallback onSimilar;
  final VoidCallback onMine;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final bottom = MediaQuery.paddingOf(context).bottom;

    Widget outlined(
      String label,
      MusubiIconData icon,
      VoidCallback onTap, {
      Color? border,
    }) => Expanded(
      child: Pressable(
        onTap: onTap,
        semanticLabel: label,
        builder: (context, pressed) => Container(
          height: 54,
          decoration: BoxDecoration(
            color: pressed ? c.surface : c.background,
            border: Border.all(color: border ?? c.border, width: 1.5),
            borderRadius: BorderRadius.circular(MusubiSizes.radiusButton),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 8,
            children: [
              MusubiIcon(
                icon,
                size: 20,
                strokeWidth: 1.9,
                color: c.textPrimary,
              ),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MusubiType.style(
                    15.5,
                    weight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Widget filled(String label, MusubiIconData icon, VoidCallback onTap) =>
        Expanded(
          child: Pressable(
            onTap: onTap,
            semanticLabel: label,
            builder: (context, pressed) => Container(
              height: 54,
              decoration: BoxDecoration(
                color: pressed ? c.brandPressed : c.brand,
                borderRadius: BorderRadius.circular(MusubiSizes.radiusButton),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 8,
                children: [
                  if (!soldOut)
                    MusubiIcon(
                      icon,
                      size: 20,
                      strokeWidth: 1.9,
                      color: c.onBrand,
                    ),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MusubiType.style(
                        15.5,
                        weight: FontWeight.w700,
                        color: c.onBrand,
                      ),
                    ),
                  ),
                  if (soldOut) MusubiIcon(icon, size: 20, color: c.onBrand),
                ],
              ),
            ),
          ),
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.background,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          12 + (bottom > 0 ? bottom : 18),
        ),
        child: Row(
          spacing: 10,
          children: [
            if (mine)
              outlined('Ver mis productos', MusubiIcons.tag, onMine)
            else if (soldOut) ...[
              outlined('Avísame', MusubiIcons.bell, onNotify),
              filled('Ver parecidos', MusubiIcons.arrowDown, onSimilar),
            ] else ...[
              Pressable(
                onTap: onMessage,
                semanticLabel: 'Enviar mensaje',
                builder: (context, pressed) => Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: pressed ? c.surface : c.background,
                    border: Border.all(color: c.border, width: 1.5),
                    borderRadius: BorderRadius.circular(
                      MusubiSizes.radiusButton,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: MusubiIcon(
                    MusubiIcons.messageCircle,
                    size: 22,
                    strokeWidth: 1.9,
                    color: c.textPrimary,
                  ),
                ),
              ),
              outlined(
                'Apartar',
                MusubiIcons.bookmark,
                onReserve,
                border: c.textPrimary,
              ),
              filled('Comprar', MusubiIcons.shoppingBag, onBuy),
            ],
          ],
        ),
      ),
    );
  }
}
