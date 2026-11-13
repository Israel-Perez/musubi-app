import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musubi_app/features/marketplace/domain/catalog_repository.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';

@immutable
class RecentProductsState {
  const new({
    required this.items,
    required this.total,
    this.nextCursor,
    this.loadingMore = false,
    this.moreError,
  });

  final List<ProductSummary> items;
  final int total;
  final String? nextCursor;
  final bool loadingMore;
  final Object? moreError;

  bool get hasMore => nextCursor != null;

  RecentProductsState copyWith({
    List<ProductSummary>? items,
    int? total,
    String? nextCursor,
    bool clearCursor = false,
    bool? loadingMore,
    Object? moreError,
    bool clearMoreError = false,
  }) => RecentProductsState(
    items: items ?? this.items,
    total: total ?? this.total,
    nextCursor: clearCursor ? null : nextCursor ?? this.nextCursor,
    loadingMore: loadingMore ?? this.loadingMore,
    moreError: clearMoreError ? null : moreError ?? this.moreError,
  );
}

final AsyncNotifierProvider<RecentProductsController, RecentProductsState>
recentProductsProvider =
    AsyncNotifierProvider<RecentProductsController, RecentProductsState>(
      RecentProductsController.new,
      retry: (_, _) => null,
      isAutoDispose: true,
    );

class RecentProductsController extends AsyncNotifier<RecentProductsState> {
  CatalogRepository get _repository => ref.read(catalogRepositoryProvider);
  bool _loadingMore = false;

  @override
  Future<RecentProductsState> build() async {
    final page = await _repository.recentProducts();
    return RecentProductsState(
      items: page.items,
      total: page.total,
      nextCursor: page.nextCursor,
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    final cursor = current?.nextCursor;
    if (current == null || cursor == null || _loadingMore) return;
    _loadingMore = true;
    state = AsyncData(
      current.copyWith(loadingMore: true, clearMoreError: true),
    );
    try {
      final page = await _repository.recentProducts(cursor: cursor);
      final latest = state.value ?? current;
      final ids = latest.items.map((item) => item.id).toSet();
      state = AsyncData(
        latest.copyWith(
          items: [
            ...latest.items,
            for (final item in page.items)
              if (ids.add(item.id)) item,
          ],
          total: page.total,
          nextCursor: page.nextCursor,
          clearCursor: page.nextCursor == null,
          loadingMore: false,
        ),
      );
    } on Object catch (error) {
      state = AsyncData(
        (state.value ?? current).copyWith(loadingMore: false, moreError: error),
      );
    } finally {
      _loadingMore = false;
    }
  }
}
