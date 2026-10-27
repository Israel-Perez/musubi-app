import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/return_path.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/app/shell/musubi_bottom_bar.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/avatars.dart';
import 'package:musubi_app/core/widgets/feedback_views.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_logo.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/core/widgets/skeleton.dart';
import 'package:musubi_app/features/auth/presentation/account_gate.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/campus_chip.dart';
import 'package:musubi_app/features/marketplace/presentation/filter_sheet.dart';
import 'package:musubi_app/features/marketplace/presentation/home_cards.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';

/// Inicio: la vitrina del campus, igual a la maqueta `Inicio-visitante` (sin
/// cuenta) e `Inicio` (con sesion), con `Inicio-cargando` e `Inicio-error`
/// (HU-48). Las acciones de miembro abren "Crea tu cuenta" sin salir.
class HomeScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final signedIn = session is SignedIn;
    final name = session is SignedIn ? session.tokens.profile?.firstName : null;
    final feed = ref.watch(homeFeedProvider);

    // Visitante: pide la cuenta. Con sesion, NOTE (HU-53): guardar; ofrecer y
    // ver el detalle llegan con HU-16 y HU-11.
    void gate(AccountGateMotive motive) {
      if (signedIn) return;
      unawaited(
        showAccountGate(context, motive: motive, returnTo: AppRoutes.home),
      );
    }

    final failure = feed is AsyncError ? feed.error : null;
    final offline = failure is ApiFailure && failure.isNetwork;
    final settled = feed is AsyncData<HomeFeed>;
    // Se termina donde empieza la barra (sin la franja de "Publicar").
    final bottom = math
        .max(0, MediaQuery.paddingOf(context).bottom - MusubiBottomBar.overhang)
        .toDouble();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: context.musubi.brand,
          onRefresh: () => ref.refresh(homeFeedProvider.future),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: signedIn
                    ? _MemberHeader(
                        name: name,
                        // `Inicio-cargando` agrega "¿Qué necesitas hoy?" y
                        // `Inicio-error` solo deja la barra de arriba.
                        greeting: failure == null,
                        subtitle: !settled,
                      )
                    : const _VisitorHeader(),
              ),
              if (offline) const SliverToBoxAdapter(child: _OfflineBanner()),
              ...switch (feed) {
                AsyncData(:final value) =>
                  signedIn
                      ? _memberContent(context, value)
                      : _visitorContent(context, ref, value, gate),
                AsyncError(:final error) => [
                  SliverToBoxAdapter(
                    child: _ErrorState(
                      failure: error is ApiFailure ? error : null,
                      onRetry: () => ref.invalidate(homeFeedProvider),
                    ),
                  ),
                ],
                _ => [
                  SliverToBoxAdapter(child: _LoadingState(member: signedIn)),
                ],
              },
              SliverToBoxAdapter(
                child: SizedBox(height: bottom + (signedIn ? 24 : 28)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _visitorContent(
    BuildContext context,
    WidgetRef ref,
    HomeFeed feed,
    void Function(AccountGateMotive) gate,
  ) {
    final filter = ref.watch(catalogFilterProvider);
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: _PopularSection(
            feed: feed,
            member: false,
            onSave: () => gate(AccountGateMotive.save),
            onEmptyAction: () => gate(AccountGateMotive.publish),
          ),
        ),
      ),
      if (feed.recent.isNotEmpty || filter.count > 0)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 22),
            child: _RecentMosaic(
              feed: feed,
              filter: filter,
              onSave: () => gate(AccountGateMotive.save),
            ),
          ),
        ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: MusubiSizes.space8),
          child: _WantedSection(
            feed: feed,
            member: false,
            onOffer: () => gate(AccountGateMotive.offer),
            onSeeAll: () => context.go(AppRoutes.wanted),
            onEmptyAction: () => gate(AccountGateMotive.request),
          ),
        ),
      ),
      const SliverToBoxAdapter(child: _JoinBanner()),
    ];
  }

  List<Widget> _memberContent(BuildContext context, HomeFeed feed) {
    // NOTE (HU-53): guardar desde la vitrina.
    void noop() {}
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 22),
          child: _PopularSection(
            feed: feed,
            member: true,
            onSave: noop,
            onEmptyAction: () => unawaited(context.push(AppRoutes.publish)),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 26),
          child: _WantedSection(
            feed: feed,
            member: true,
            onOffer: noop,
            onSeeAll: () => context.go(AppRoutes.wanted),
            onEmptyAction: () => unawaited(context.push(AppRoutes.publish)),
          ),
        ),
      ),
      if (feed.recent.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 26),
            child: _MemberRecent(feed: feed, onSave: noop),
          ),
        ),
    ];
  }
}

/// Encabezado de visitante: logo, chip del campus y "Entrar".
class _VisitorHeader extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MusubiSizes.space4),
      child: SizedBox(
        height: MusubiSizes.minTouch,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          spacing: MusubiSizes.space2,
          children: [
            // Con letra grande el logotipo se reduce antes que desbordar.
            const Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: MusubiLogo(),
              ),
            ),
            const CampusChip(signedIn: false),
            Pressable(
              key: const Key('home-enter'),
              semanticLabel: 'Entrar',
              onTap: () => context.go(
                Uri(
                  path: AppRoutes.signIn,
                  queryParameters: {AppRoutes.returnParam: AppRoutes.home},
                ).toString(),
              ),
              builder: (context, pressed) => SizedBox(
                height: MusubiSizes.minTouch,
                child: Center(
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.only(left: 12, right: 15),
                    decoration: BoxDecoration(
                      color: pressed ? c.surface : c.background,
                      borderRadius: BorderRadius.circular(
                        MusubiSizes.radiusChip,
                      ),
                      border: Border.all(color: c.border, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 6,
                      children: [
                        MusubiIcon(
                          MusubiIcons.userRound,
                          size: 18,
                          color: c.textPrimary,
                        ),
                        Text(
                          'Entrar',
                          style: MusubiType.style(
                            14,
                            weight: FontWeight.w700,
                            color: c.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Encabezado con sesion (`Inicio`): logo, campus verificado, campana,
/// "Hola, Ana" y el buscador.
class _MemberHeader extends StatelessWidget {
  const new({
    required this.name,
    required this.greeting,
    required this.subtitle,
  });

  final String? name;

  /// Saludo y buscador (no van en `Inicio-error`).
  final bool greeting;

  /// "¿Qué necesitas hoy?" bajo el saludo (`Inicio-cargando`/`-error`).
  final bool subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 10),
          child: SizedBox(
            height: MusubiSizes.minTouch,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Con letra grande el logotipo se reduce antes que desbordar.
                const Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: MusubiLogo(),
                  ),
                ),
                const CampusChip(signedIn: true),
                Pressable(
                  // NOTE (HU-31): avisos de la app.
                  onTap: () => unawaited(context.push(AppRoutes.notifications)),
                  semanticLabel: 'Notificaciones',
                  builder: (context, _) => SizedBox.square(
                    dimension: MusubiSizes.minTouch,
                    child: Center(
                      child: MusubiIcon(
                        MusubiIcons.bell,
                        strokeWidth: 1.9,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (greeting) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    name == null ? 'Hola' : 'Hola, $name',
                    style: MusubiType.title1.copyWith(
                      letterSpacing: -0.025 * 26,
                      color: c.textPrimary,
                    ),
                  ),
                ),
                if (subtitle)
                  Text(
                    '¿Qué necesitas hoy?',
                    style: MusubiType.body.copyWith(color: c.textSecondary),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Row(
              spacing: 10,
              children: [
                Expanded(
                  child: Pressable(
                    // NOTE (HU-09): busqueda.
                    onTap: () => unawaited(context.push(AppRoutes.search)),
                    semanticLabel: 'Buscar',
                    builder: (context, pressed) => Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: pressed ? c.surfacePressed : c.surface,
                        borderRadius: BorderRadius.circular(
                          MusubiSizes.radiusButton,
                        ),
                      ),
                      child: Row(
                        spacing: 10,
                        children: [
                          MusubiIcon(
                            MusubiIcons.search,
                            size: 20,
                            color: c.textPrimary,
                          ),
                          Expanded(
                            child: Text(
                              'Busca libros, laptops, batas…',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: MusubiType.style(
                                15,
                                color: c.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Pressable(
                  // NOTE (HU-10): filtros de la busqueda.
                  onTap: () => unawaited(context.push(AppRoutes.search)),
                  semanticLabel: 'Filtros',
                  builder: (context, pressed) => Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: pressed ? c.surfacePressed : c.surface,
                      borderRadius: BorderRadius.circular(
                        MusubiSizes.radiusButton,
                      ),
                    ),
                    child: Center(
                      child: MusubiIcon(
                        MusubiIcons.slidersHorizontal,
                        size: 20,
                        strokeWidth: 1.9,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Fila horizontal de tarjetas con el margen de la maqueta.
class _HorizontalRow extends StatelessWidget {
  const new({required this.padding, required this.children});

  final EdgeInsets padding;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: padding,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: MusubiSizes.space3,
      children: children,
    ),
  );
}

/// Titulo de seccion con su icono opcional y "Ver todo".
class _SectionTitle extends StatelessWidget {
  const new({
    required this.title,
    required this.size,
    this.icon,
    this.onSeeAll,
    this.seeAllChevron = false,
    this.trailing,
  });

  final String title;

  /// 20/26 (visitante) o 19/24 (con sesion).
  final double size;
  final MusubiIconData? icon;
  final VoidCallback? onSeeAll;
  final bool seeAllChevron;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MusubiSizes.gutter),
      child: Row(
        spacing: MusubiSizes.space3,
        children: [
          Expanded(
            child: Row(
              spacing: MusubiSizes.space2,
              children: [
                if (icon != null)
                  MusubiIcon(
                    icon!,
                    size: 20,
                    strokeWidth: size == 20 ? 2.2 : 2,
                    color: c.brandText,
                  ),
                Flexible(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: MusubiType.style(
                        size,
                        weight: FontWeight.w800,
                        line: size == 20 ? 26 : 24,
                        em: -0.02,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (onSeeAll != null)
            SizedBox(
              height: 26,
              child: OverflowBox(
                maxHeight: MusubiSizes.minTouch,
                fit: OverflowBoxFit.deferToChild,
                child: MusubiButton(
                  label: 'Ver todo',
                  kind: MusubiButtonKind.link,
                  trailingIcon: seeAllChevron ? MusubiIcons.chevronRight : null,
                  iconSize: 16,
                  onPressed: onSeeAll,
                ),
              ),
            ),
          ?trailing,
        ],
      ),
    );
  }
}

/// "Populares" con Hoy / Semana y las tarjetas con su lugar.
class _PopularSection extends ConsumerWidget {
  const new({
    required this.feed,
    required this.member,
    required this.onSave,
    required this.onEmptyAction,
  });

  final HomeFeed feed;
  final bool member;
  final VoidCallback onSave;
  final VoidCallback onEmptyAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.musubi;
    final period = ref.watch(popularPeriodProvider);
    final title = Row(
      spacing: member ? 8 : 10,
      children: [
        if (member)
          MusubiIcon(
            MusubiIcons.flame,
            size: 20,
            strokeWidth: 2.2,
            color: c.brandText,
          )
        else
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: c.brand,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: MusubiIcon(
                MusubiIcons.flame,
                size: 19,
                strokeWidth: 2.2,
                color: Color(0xFFFFFFFF),
              ),
            ),
          ),
        Flexible(
          child: Semantics(
            header: true,
            child: Text(
              'Populares',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: MusubiType.style(
                member ? 19 : 22,
                weight: FontWeight.w800,
                line: member ? 24 : 28,
                em: member ? -0.02 : -0.025,
                color: c.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 16),
          child: SizedBox(
            height: member ? 24 : 44,
            child: OverflowBox(
              maxHeight: 44,
              child: Row(
                children: [
                  Expanded(child: title),
                  _PeriodSwitch(
                    period: period,
                    onSelect: (option) =>
                        ref.read(popularPeriodProvider.notifier).select(option),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (feed.popular.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: EmptyShelf(
              key: const Key('home-empty-products'),
              icon: MusubiIcons.shoppingBag,
              title: 'Todavía no hay publicaciones en la UTTT',
              message: 'Cuando alguien de tu campus venda algo, lo verás aquí.',
              actionLabel: 'Vender algo',
              onAction: onEmptyAction,
            ),
          )
        else
          _HorizontalRow(
            padding: member
                ? const EdgeInsets.fromLTRB(20, 14, 20, 0)
                : const EdgeInsets.fromLTRB(20, 12, 20, 6),
            children: [
              for (var i = 0; i < feed.popular.length; i++)
                RiseIn(
                  key: ValueKey('${period.name}-${feed.popular[i].id}'),
                  child: PopularCard(
                    rank: i + 1,
                    product: feed.popular[i],
                    member: member,
                    onSave: onSave,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

/// Hoy / Semana: pastilla blanca con sombra sobre la gris.
class _PeriodSwitch extends StatelessWidget {
  const new({required this.period, required this.onSelect});

  final PopularPeriod period;
  final ValueChanged<PopularPeriod> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Semantics(
      label: 'Populares de',
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in PopularPeriod.values)
              Pressable(
                onTap: () => onSelect(option),
                semanticLabel: option.label,
                selected: option == period,
                builder: (context, _) {
                  final selected = option == period;
                  return SizedBox(
                    height: 44,
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected ? c.background : Colors.transparent,
                          borderRadius: BorderRadius.circular(
                            MusubiSizes.radiusChip,
                          ),
                          boxShadow: selected
                              ? const [
                                  BoxShadow(
                                    color: Color(0x241C1C1E),
                                    offset: Offset(0, 1),
                                    blurRadius: 3,
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          option.label,
                          style: MusubiType.style(
                            13.5,
                            weight: selected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: selected ? c.textPrimary : c.textTertiary,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// "Recién publicados" de visitante: mosaico de dos columnas y "Filtrar".
class _RecentMosaic extends StatelessWidget {
  const new({required this.feed, required this.filter, required this.onSave});

  final HomeFeed feed;
  final CatalogFilter filter;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final category = filter.category;
    final title = category == null
        ? 'Recién publicados'
        : feed.categories
                  .where((option) => option.slug == category)
                  .firstOrNull
                  ?.name ??
              'Recién publicados';
    final left = <Widget>[];
    final right = <Widget>[];
    // El mosaico de la maqueta muestra hasta 6.
    for (final (i, product) in feed.recent.take(6).indexed) {
      // Alturas alternadas de la maqueta: 200, 156, 156, 200...
      final tall = i % 4 == 0 || i % 4 == 3;
      final tile = RiseIn(
        duration: const Duration(milliseconds: 450),
        delay: i.isEven ? Duration.zero : const Duration(milliseconds: 80),
        child: MosaicTile(
          product: product,
          height: tall ? 200 : 156,
          onSave: onSave,
        ),
      );
      (i.isEven ? left : right).add(tile);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          title: title,
          size: 20,
          trailing: feed.categories.isEmpty
              ? null
              : _FilterButton(
                  count: filter.count,
                  onTap: () =>
                      unawaited(showFilterSheet(context, feed.categories)),
                ),
        ),
        if (feed.recent.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text(
              'No hay productos con ese filtro.',
              style: MusubiType.body.copyWith(color: c.textSecondary),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: MusubiSizes.space3,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: MusubiSizes.space4,
                    children: left,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: MusubiSizes.space4,
                    children: right,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Boton "Filtrar" de 44 con el globo de filtros activos.
class _FilterButton extends StatelessWidget {
  const new({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Pressable(
      key: const Key('home-filter'),
      onTap: onTap,
      semanticLabel: switch (count) {
        0 => 'Filtrar',
        1 => 'Filtrar, 1 filtro activo',
        _ => 'Filtrar, $count filtros activos',
      },
      builder: (context, pressed) => SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: pressed ? c.surfacePressed : c.surface,
                  borderRadius: BorderRadius.circular(MusubiSizes.radiusField),
                ),
                child: Center(
                  child: MusubiIcon(
                    MusubiIcons.slidersHorizontal,
                    size: 20,
                    color: c.textPrimary,
                  ),
                ),
              ),
            ),
            if (count > 0)
              Positioned(
                top: -5,
                right: -5,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 20),
                  height: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: c.brand,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: c.background, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$count',
                    style: MusubiType.style(
                      10.5,
                      weight: FontWeight.w800,
                      color: const Color(0xFFFFFFFF),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// "Se busca" (visitante) o "Se busca en tu comunidad" (con sesion).
class _WantedSection extends ConsumerWidget {
  const new({
    required this.feed,
    required this.member,
    required this.onOffer,
    required this.onSeeAll,
    required this.onEmptyAction,
  });

  final HomeFeed feed;
  final bool member;
  final VoidCallback onOffer;
  final VoidCallback onSeeAll;
  final VoidCallback onEmptyAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          title: member ? 'Se busca en tu comunidad' : 'Se busca',
          size: member ? 19 : 20,
          icon: MusubiIcons.megaphone,
          onSeeAll: onSeeAll,
          seeAllChevron: !member,
        ),
        if (feed.wanted.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: EmptyShelf(
              key: const Key('home-empty-wanted'),
              icon: MusubiIcons.megaphone,
              title: 'Nadie ha pedido nada todavía',
              message: 'Pide lo que necesitas y recibe ofertas de tu campus.',
              actionLabel: 'Pedir algo',
              tinted: true,
              onAction: onEmptyAction,
            ),
          )
        else
          _HorizontalRow(
            padding: member
                ? const EdgeInsets.fromLTRB(20, 12, 20, 0)
                : const EdgeInsets.fromLTRB(20, 12, 20, 4),
            children: [
              for (final wanted in feed.wanted)
                WantedTicket(
                  wanted: wanted,
                  member: member,
                  now: now,
                  onOffer: onOffer,
                ),
            ],
          ),
      ],
    );
  }
}

/// "Publicaciones recientes" con sesion: cuatro en cuadricula y "Ver todo".
class _MemberRecent extends ConsumerWidget {
  const new({required this.feed, required this.onSave});

  final HomeFeed feed;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final newest = feed.newestFirst;
    final shown = newest.take(4).toList();
    final rows = [
      for (var i = 0; i < shown.length; i += 2) shown.skip(i).take(2).toList(),
    ];
    // NOTE (HU-49): "Ver todo" abre la lista completa.
    void seeAll() => unawaited(context.push(AppRoutes.search));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          title: 'Publicaciones recientes',
          size: 19,
          onSeeAll: seeAll,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Column(
            spacing: 20,
            children: [
              for (final row in rows)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: MusubiSizes.space3,
                  children: [
                    for (final product in row)
                      Expanded(
                        child: RecentTile(
                          product: product,
                          now: now,
                          onSave: onSave,
                        ),
                      ),
                    if (row.length == 1) const Spacer(),
                  ],
                ),
            ],
          ),
        ),
        if (feed.recentTotal > shown.length)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: SeeAllNewCard(
              photos: [
                for (final product in newest.skip(shown.length))
                  product.photoUrl,
              ],
              total: feed.recentTotal,
              onTap: seeAll,
            ),
          ),
      ],
    );
  }
}

/// "La UTTT ya está en Musubi · Crear cuenta" (solo visitantes).
class _JoinBanner extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.musubi;
    return Container(
      key: const Key('home-join-banner'),
      margin: const EdgeInsets.fromLTRB(20, MusubiSizes.space8, 20, 0),
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
      decoration: BoxDecoration(
        color: c.inverse,
        borderRadius: BorderRadius.circular(MusubiSizes.radiusSheet),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: CommunityAvatars(
              size: 42,
              overlap: 10,
              borderColor: c.inverse,
              borderWidth: 3,
              fontSize: 13,
              plus: true,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'La UTTT ya está en Musubi',
            textAlign: TextAlign.center,
            style: MusubiType.style(
              22,
              weight: FontWeight.w800,
              line: 28,
              em: -0.02,
              color: const Color(0xFFFFFFFF),
            ),
          ),
          const SizedBox(height: 18),
          MusubiButton(
            label: 'Crear cuenta',
            height: MusubiSizes.buttonHeightSheet,
            onPressed: () {
              ref.read(returnPathProvider.notifier).remember(AppRoutes.home);
              context.go(AppRoutes.signUp);
            },
          ),
        ],
      ),
    );
  }
}

/// `Inicio-cargando`: la forma de la vitrina mientras llega.
class _LoadingState extends StatelessWidget {
  const new({required this.member});

  final bool member;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    Widget card() => const SizedBox(
      width: 156,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: MusubiSizes.space2,
        children: [
          SkeletonBox(width: double.infinity, height: 140, radius: 16),
          SkeletonBox(width: 60, height: 16, radius: 5),
          SkeletonBox(width: 140, height: 12, radius: 5),
          SkeletonBox(width: 96, height: 12, radius: 5),
        ],
      ),
    );
    Widget heading(double first, double second) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: MusubiSizes.space2,
      children: [
        SkeletonBox(width: first, height: 20, radius: 6),
        SkeletonBox(width: second, height: 13, radius: 5),
      ],
    );
    Widget ticket({bool filled = false}) => Container(
      width: 290,
      height: 150,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: c.brandFaint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: filled
          ? const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                SkeletonBox(width: 84, height: 22, radius: 999, brand: true),
                SkeletonBox(width: 220, height: 16, radius: 5, brand: true),
                SkeletonBox(width: 160, height: 16, radius: 5, brand: true),
                Spacer(),
                SkeletonBox(width: 110, height: 26, radius: 6, brand: true),
              ],
            )
          : null,
    );

    return Semantics(
      label: 'Cargando publicaciones…',
      liveRegion: true,
      child: ExcludeSemantics(
        child: SkeletonShimmer(
          child: ClipRect(
            child: Padding(
              key: const Key('home-loading'),
              padding: const EdgeInsets.only(left: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (member) ...[
                    const SizedBox(height: 16),
                    const SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: NeverScrollableScrollPhysics(),
                      child: Row(
                        spacing: 8,
                        children: [
                          SkeletonBox(width: 74, height: 38, radius: 999),
                          SkeletonBox(width: 132, height: 38, radius: 999),
                          SkeletonBox(width: 88, height: 38, radius: 999),
                          SkeletonBox(width: 96, height: 38, radius: 999),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: member ? 28 : 16),
                  heading(190, 150),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: MusubiSizes.space3,
                      children: [card(), card(), card()],
                    ),
                  ),
                  const SizedBox(height: 30),
                  heading(220, 170),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Row(
                      spacing: MusubiSizes.space3,
                      children: [ticket(filled: true), ticket()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Sin conexión a internet" (maqueta `Inicio-error`).
class _OfflineBanner extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => RiseIn(
    offset: -12,
    child: Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.musubi.inverse,
        borderRadius: BorderRadius.circular(MusubiSizes.radiusField),
      ),
      child: Semantics(
        liveRegion: true,
        child: Row(
          spacing: 10,
          children: [
            const MusubiIcon(
              MusubiIcons.wifiOff,
              size: 18,
              color: Color(0xFFFFFFFF),
            ),
            Expanded(
              child: Text(
                'Sin conexión a internet',
                style: MusubiType.style(
                  13.5,
                  weight: FontWeight.w700,
                  color: const Color(0xFFFFFFFF),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// "No pudimos cargar las publicaciones" + Reintentar.
class _ErrorState extends StatelessWidget {
  const new({required this.failure, required this.onRetry});

  final ApiFailure? failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final network = failure?.isNetwork ?? false;
    return RiseIn(
      offset: 12,
      duration: const Duration(milliseconds: 450),
      delay: const Duration(milliseconds: 100),
      child: Padding(
        key: const Key('home-error'),
        padding: const EdgeInsets.fromLTRB(28, 36, 28, 0),
        child: Semantics(
          liveRegion: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: SizedBox.square(
                  dimension: 112,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: c.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: MusubiIcon(
                            network
                                ? MusubiIcons.wifiOff
                                : MusubiIcons.circleAlert,
                            size: 48,
                            strokeWidth: 1.5,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: c.errorFill,
                            shape: BoxShape.circle,
                            border: Border.all(color: c.background, width: 3),
                          ),
                          child: const Center(
                            child: MusubiIcon(
                              MusubiIcons.exclamation,
                              size: 16,
                              strokeWidth: 3,
                              color: Color(0xFFFFFFFF),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: c.errorSoft,
                    borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 6,
                    children: [
                      MusubiIcon(
                        MusubiIcons.circleAlert,
                        size: 14,
                        strokeWidth: 2.4,
                        color: c.error,
                      ),
                      Text(
                        network ? 'Error de conexión' : 'Error del servidor',
                        style: MusubiType.style(
                          12.5,
                          weight: FontWeight.w800,
                          color: c.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'No pudimos cargar las publicaciones',
                textAlign: TextAlign.center,
                style: MusubiType.style(
                  23,
                  weight: FontWeight.w800,
                  line: 29,
                  em: -0.025,
                  color: c.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              // NOTE (HU-53): con favoritos locales, "Lo que guardaste sigue
              // disponible." y la fila "Guardado en tu teléfono".
              Text(
                network
                    ? 'Revisa tu internet o tus datos móviles e inténtalo de '
                          'nuevo.'
                    : failure?.message ?? 'Inténtalo de nuevo en un momento.',
                textAlign: TextAlign.center,
                style: MusubiType.body.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: 20),
              MusubiButton(
                label: 'Reintentar',
                icon: MusubiIcons.refreshCw,
                iconSize: 19,
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
