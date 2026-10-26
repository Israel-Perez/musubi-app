import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/return_path.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_logo.dart';
import 'package:musubi_app/features/auth/presentation/account_gate.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/campus_chip.dart';
import 'package:musubi_app/features/marketplace/presentation/home_cards.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';

/// Inicio: la vitrina del campus (maqueta `Inicio-visitante` / `Inicio`,
/// HU-48). La app abre aqui, con o sin cuenta; las acciones de miembro abren
/// "Crea tu cuenta" sin salir de la pantalla.
class HomeScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(sessionControllerProvider) is SignedIn;
    final feed = ref.watch(homeFeedProvider);

    // Visitante: pide la cuenta. Con sesion, NOTE (HU-53): guardar; ofrecer y
    // ver el detalle llegan con HU-16 y HU-11.
    void gate(AccountGateMotive motive) {
      if (signedIn) return;
      unawaited(
        showAccountGate(context, motive: motive, returnTo: AppRoutes.home),
      );
    }

    final offline =
        feed is AsyncError &&
        feed.error is ApiFailure &&
        (feed.error! as ApiFailure).isNetwork;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(homeFeedProvider.future),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  MusubiSizes.gutter,
                  MusubiSizes.space3,
                  MusubiSizes.gutter,
                  0,
                ),
                sliver: SliverToBoxAdapter(child: _Header(signedIn: signedIn)),
              ),
              if (offline)
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    MusubiSizes.gutter,
                    MusubiSizes.space4,
                    MusubiSizes.gutter,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(child: _OfflineBanner()),
                ),
              ...switch (feed) {
                AsyncData(:final value) => _content(
                  context,
                  ref,
                  value,
                  signedIn: signedIn,
                  gate: gate,
                ),
                AsyncError(:final error) => [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _ErrorState(
                      failure: error is ApiFailure ? error : null,
                      onRetry: () => ref.invalidate(homeFeedProvider),
                    ),
                  ),
                ],
                _ => const [SliverToBoxAdapter(child: _LoadingState())],
              },
              const SliverToBoxAdapter(
                child: SizedBox(height: MusubiSizes.space8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _content(
    BuildContext context,
    WidgetRef ref,
    HomeFeed feed, {
    required bool signedIn,
    required void Function(AccountGateMotive) gate,
  }) {
    final textTheme = Theme.of(context).textTheme;
    Widget padded(Widget child, {double top = MusubiSizes.space6}) =>
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            MusubiSizes.gutter,
            top,
            MusubiSizes.gutter,
            0,
          ),
          sliver: SliverToBoxAdapter(child: child),
        );

    return [
      padded(const _PopularHeader()),
      if (feed.popular.isEmpty)
        padded(
          _EmptyCard(
            key: const Key('home-empty-products'),
            icon: Icons.storefront_outlined,
            title: 'Todavía no hay publicaciones en la UTTT',
            message: 'Cuando alguien de tu campus venda algo, lo verás aquí.',
            actionLabel: 'Vender algo',
            onAction: () => signedIn
                ? unawaited(context.push(AppRoutes.publish))
                : gate(AccountGateMotive.publish),
          ),
          top: MusubiSizes.space3,
        )
      else
        SliverToBoxAdapter(
          child: _HorizontalRow(
            children: [
              for (var i = 0; i < feed.popular.length; i++)
                PopularCard(
                  rank: i + 1,
                  product: feed.popular[i],
                  onSave: () => gate(AccountGateMotive.save),
                ),
            ],
          ),
        ),
      if (feed.recent.isNotEmpty) ...[
        padded(
          Text(
            'Recién publicados',
            style: textTheme.titleLarge?.copyWith(fontSize: 22),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            MusubiSizes.gutter,
            MusubiSizes.space3,
            MusubiSizes.gutter,
            0,
          ),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: MusubiSizes.space4,
              crossAxisSpacing: MusubiSizes.space3,
              mainAxisExtent: 212,
            ),
            itemCount: feed.recent.length,
            itemBuilder: (_, i) => ProductTile(
              product: feed.recent[i],
              onSave: () => gate(AccountGateMotive.save),
            ),
          ),
        ),
      ],
      padded(_WantedHeader(onSeeAll: () => context.go(AppRoutes.wanted))),
      if (feed.wanted.isEmpty)
        padded(
          _EmptyCard(
            key: const Key('home-empty-wanted'),
            icon: Icons.campaign_outlined,
            title: 'Nadie ha pedido nada todavía',
            message: 'Pide lo que necesitas y recibe ofertas de tu campus.',
            actionLabel: 'Pedir algo',
            tinted: true,
            onAction: () => signedIn
                ? unawaited(context.push(AppRoutes.publish))
                : gate(AccountGateMotive.request),
          ),
          top: MusubiSizes.space3,
        )
      else
        SliverToBoxAdapter(
          child: _HorizontalRow(
            children: [
              for (final wanted in feed.wanted)
                WantedTicket(
                  wanted: wanted,
                  onOffer: () => gate(AccountGateMotive.offer),
                ),
            ],
          ),
        ),
      if (!signedIn) padded(const _JoinBanner()),
    ];
  }
}

/// Fila horizontal que toma el alto de su contenido (no se desborda con
/// textos de dos lineas ni con la letra grande del sistema). La vitrina
/// muestra pocas tarjetas por seccion; la lista completa vive en "Ver todo".
class _HorizontalRow extends StatelessWidget {
  const new({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.fromLTRB(
      MusubiSizes.gutter,
      MusubiSizes.space3,
      MusubiSizes.gutter,
      0,
    ),
    child: IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: MusubiSizes.space3),
            children[i],
          ],
        ],
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  const new({required this.signedIn});

  final bool signedIn;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Row(
      children: [
        const MusubiLogo(),
        const SizedBox(width: MusubiSizes.space3),
        CampusChip(signedIn: signedIn),
        const Spacer(),
        if (!signedIn)
          SizedBox(
            height: 40,
            child: OutlinedButton.icon(
              key: const Key('home-enter'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: const StadiumBorder(),
                side: BorderSide(color: c.border, width: 1.5),
                foregroundColor: c.textPrimary,
                textStyle: MusubiType.label.copyWith(fontSize: 14),
              ),
              onPressed: () => context.go(
                Uri(
                  path: AppRoutes.signIn,
                  queryParameters: {AppRoutes.returnParam: AppRoutes.home},
                ).toString(),
              ),
              icon: const Icon(Icons.person_outline, size: 18),
              label: const Text('Entrar'),
            ),
          ),
      ],
    );
  }
}

class _PopularHeader extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.musubi;
    final period = ref.watch(popularPeriodProvider);
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: c.brand,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.local_fire_department_outlined,
            size: 22,
            color: c.onBrand,
          ),
        ),
        const SizedBox(width: MusubiSizes.space2),
        Expanded(
          child: Text(
            'Populares',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontSize: 22),
          ),
        ),
        Semantics(
          label: 'Populares de',
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final option in PopularPeriod.values)
                  _Segment(
                    label: option.label,
                    selected: option == period,
                    onTap: () =>
                        ref.read(popularPeriodProvider.notifier).select(option),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const new({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 34),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? c.background : Colors.transparent,
            borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
          ),
          child: Text(
            label,
            style: MusubiType.label.copyWith(
              fontSize: 13.5,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? c.textPrimary : c.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _WantedHeader extends StatelessWidget {
  const new({required this.onSeeAll});

  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Row(
      children: [
        Icon(Icons.campaign_outlined, color: c.brandText),
        const SizedBox(width: MusubiSizes.space2),
        Expanded(
          child: Text(
            'Se busca',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontSize: 22),
          ),
        ),
        TextButton(
          onPressed: onSeeAll,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [Text('Ver todo'), Icon(Icons.chevron_right, size: 20)],
          ),
        ),
      ],
    );
  }
}

/// Seccion sin datos todavia: dice por que y que hacer.
class _EmptyCard extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.tinted = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(MusubiSizes.space4),
      decoration: BoxDecoration(
        color: tinted ? c.brandSoft : c.surface,
        borderRadius: BorderRadius.circular(MusubiSizes.radiusWanted),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: c.brandText),
          const SizedBox(height: MusubiSizes.space2),
          Text(
            title,
            textAlign: TextAlign.center,
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: MusubiSizes.space1),
          Text(
            message,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: MusubiSizes.space3),
          SizedBox(
            height: MusubiSizes.buttonHeightCard,
            child: FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ),
        ],
      ),
    );
  }
}

/// "La UTTT ya está en Musubi · Crear cuenta" (solo visitantes).
class _JoinBanner extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.musubi;
    const ink = Color(0xFF1C1C1E);
    return Container(
      key: const Key('home-join-banner'),
      padding: const EdgeInsets.all(MusubiSizes.space6),
      decoration: BoxDecoration(
        color: c.background == MusubiColors.dark.background ? c.surface : ink,
        borderRadius: BorderRadius.circular(MusubiSizes.radiusWanted),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CampusAvatars(size: 34, border: ink),
              const SizedBox(width: 4),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: c.brand,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add, size: 20, color: c.onBrand),
              ),
            ],
          ),
          const SizedBox(height: MusubiSizes.space3),
          Text(
            'La UTTT ya está en Musubi',
            textAlign: TextAlign.center,
            style: MusubiType.title2.copyWith(
              fontSize: 22,
              color: const Color(0xFFFFFFFF),
            ),
          ),
          const SizedBox(height: MusubiSizes.space4),
          MusubiButton(
            label: 'Crear cuenta',
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

/// Maqueta `Inicio-cargando`: la forma de la vitrina mientras llega.
class _LoadingState extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    Widget block(double width, double height, {double radius = 8}) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
    return Semantics(
      label: 'Cargando publicaciones…',
      liveRegion: true,
      child: ExcludeSemantics(
        child: Padding(
          key: const Key('home-loading'),
          padding: const EdgeInsets.fromLTRB(
            MusubiSizes.gutter,
            MusubiSizes.space6,
            MusubiSizes.gutter,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              block(190, 22),
              const SizedBox(height: MusubiSizes.space2),
              block(150, 12),
              const SizedBox(height: MusubiSizes.space4),
              Row(
                children: [
                  Expanded(child: block(double.infinity, 140, radius: 16)),
                  const SizedBox(width: MusubiSizes.space3),
                  Expanded(child: block(double.infinity, 140, radius: 16)),
                ],
              ),
              const SizedBox(height: MusubiSizes.space3),
              block(140, 12),
              const SizedBox(height: MusubiSizes.space6),
              block(220, 22),
              const SizedBox(height: MusubiSizes.space4),
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: c.brandSoft.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(MusubiSizes.radiusWanted),
                ),
              ),
            ],
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: MusubiSizes.space4,
      vertical: 10,
    ),
    decoration: BoxDecoration(
      color: const Color(0xFF1C1C1E),
      borderRadius: BorderRadius.circular(MusubiSizes.radiusThumb),
    ),
    child: Row(
      children: [
        const Icon(Icons.wifi_off, size: 18, color: Color(0xFFFFFFFF)),
        const SizedBox(width: MusubiSizes.space2),
        Text(
          'Sin conexión a internet',
          style: MusubiType.label.copyWith(
            fontSize: 13.5,
            color: const Color(0xFFFFFFFF),
          ),
        ),
      ],
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
    final textTheme = Theme.of(context).textTheme;
    final network = failure?.isNetwork ?? false;
    return Padding(
      key: const Key('home-error'),
      padding: const EdgeInsets.all(MusubiSizes.gutter),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  color: c.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  network ? Icons.wifi_off : Icons.cloud_off_outlined,
                  size: 44,
                  color: c.textPrimary,
                ),
              ),
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: c.error,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '!',
                    style: MusubiType.label.copyWith(
                      color: const Color(0xFFFFFFFF),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: MusubiSizes.space4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: c.errorSoft,
              borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 14, color: c.error),
                const SizedBox(width: 4),
                Text(
                  network ? 'Error de conexión' : 'Error del servidor',
                  style: MusubiType.label.copyWith(color: c.error),
                ),
              ],
            ),
          ),
          const SizedBox(height: MusubiSizes.space3),
          Text(
            'No pudimos cargar las publicaciones',
            textAlign: TextAlign.center,
            style: textTheme.titleLarge?.copyWith(fontSize: 22),
          ),
          const SizedBox(height: MusubiSizes.space2),
          Text(
            network
                ? 'Revisa tu internet o tus datos móviles e inténtalo de nuevo.'
                : failure?.message ?? 'Inténtalo de nuevo en un momento.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: MusubiSizes.space6),
          MusubiButton(
            label: 'Reintentar',
            icon: Icons.refresh,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
