import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/feedback_views.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/features/auth/presentation/account_gate.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/favorites_actions.dart';
import 'package:musubi_app/features/marketplace/presentation/home_cards.dart';
import 'package:musubi_app/features/marketplace/presentation/recent_products_provider.dart';

class RecentProductsScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(recentProductsProvider);
    final now = ref.watch(clockProvider)();
    final signedIn = ref.watch(sessionControllerProvider) is SignedIn;

    Future<void> save(ProductSummary product) async {
      if (!signedIn) {
        await showAccountGate(
          context,
          motive: AccountGateMotive.save,
          returnTo: AppRoutes.recentProducts,
        );
        return;
      }
      await toggleFavorite(context, ref, product);
    }

    return Scaffold(
      backgroundColor: context.musubi.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(onBack: () => context.pop()),
            Expanded(
              child: switch (result) {
                AsyncData(:final value) => _ProductsList(
                  state: value,
                  now: now,
                  onSave: save,
                  onOpen: (product) => unawaited(
                    context.push(AppRoutes.product(product.id), extra: product),
                  ),
                  onLoadMore: () => unawaited(
                    ref.read(recentProductsProvider.notifier).loadMore(),
                  ),
                ),
                AsyncError(:final error) => ErrorView(
                  message: error is ApiFailure
                      ? error.message
                      : 'No pudimos cargar las publicaciones.',
                  onRetry: () => ref.invalidate(recentProductsProvider),
                ),
                _ => const LoadingView(
                  message: 'Cargando publicaciones recientes…',
                ),
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
      padding: const EdgeInsets.fromLTRB(8, 10, 20, 8),
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
              'Recién publicados',
              style: MusubiType.style(
                22,
                weight: FontWeight.w800,
                line: 28,
                color: c.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductsList extends StatelessWidget {
  const new({
    required this.state,
    required this.now,
    required this.onSave,
    required this.onOpen,
    required this.onLoadMore,
  });

  final RecentProductsState state;
  final DateTime now;
  final ValueChanged<ProductSummary> onSave;
  final ValueChanged<ProductSummary> onOpen;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (state.items.isEmpty) {
      return const EmptyView(
        title: 'Todavía no hay publicaciones',
        message: 'Todavía no hay publicaciones disponibles.',
      );
    }
    return GridView.builder(
      key: const Key('recent-products-list'),
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.paddingOf(context).bottom + 24,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 12,
        mainAxisExtent: 242,
      ),
      itemCount:
          state.items.length +
          (state.hasMore || state.moreError != null ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < state.items.length) {
          final product = state.items[index];
          return RecentTile(
            product: product,
            now: now,
            onSave: onSave,
            onTap: () => onOpen(product),
          );
        }
        final error = state.moreError;
        if (error != null) {
          return Center(
            child: TextButton(
              onPressed: onLoadMore,
              child: const Text('Reintentar'),
            ),
          );
        }
        return Center(
          child: state.loadingMore
              ? const CircularProgressIndicator()
              : MusubiButton(
                  label: 'Más antiguas',
                  onPressed: onLoadMore,
                  kind: MusubiButtonKind.secondary,
                ),
        );
      },
    );
  }
}
