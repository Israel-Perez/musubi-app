import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/feedback_views.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/core/widgets/top_bar.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/domain/saved_search.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';
import 'package:musubi_app/features/marketplace/presentation/saved_search_providers.dart';

/// "Mis alertas" (HU-12, `Ajustes` → Preferencias; la maqueta no la dibuja,
/// decision de la usuaria del 14-Nov-2026): las busquedas guardadas con
/// "Avísame cuando aparezca", sus filtros, cuando vencen y "Quitar".
class SavedSearchesScreen extends ConsumerWidget {
  const new({super.key});

  /// Lo que dice debajo de la busqueda: categorias, precio y estado.
  static String summary(SavedSearch search, Map<String, String> names) {
    final parts = <String>[
      for (final slug in search.categories) names[slug] ?? slug,
      switch ((search.minCents, search.maxCents)) {
        (final int min, final int max) =>
          '${formatPrice(min)} a ${formatPrice(max)}',
        (final int min, null) => 'Desde ${formatPrice(min)}',
        (null, final int max) => 'Hasta ${formatPrice(max)}',
        _ => '',
      },
      switch (search.condition) {
        'new' => 'Nuevo',
        'used' => 'Usado',
        _ => '',
      },
    ].where((part) => part.isNotEmpty).toList();
    return parts.isEmpty ? 'Cualquier categoría y precio' : parts.join(' · ');
  }

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    SavedSearch search,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(savedSearchRepositoryProvider).remove(search.id);
      ref.invalidate(mySavedSearchesProvider);
      showMusubiSnack(
        messenger,
        'Quitamos la alerta de «${search.query}»',
        icon: MusubiIcons.bellOff,
        tone: SnackTone.info,
      );
    } on ApiFailure catch (failure) {
      showMusubiSnack(
        messenger,
        failure.message,
        icon: MusubiIcons.circleAlert,
        tone: SnackTone.warn,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.musubi;
    final searches = ref.watch(mySavedSearchesProvider);
    final names = {
      for (final category
          in ref.watch(categoriesProvider).value ?? const <CatalogCategory>[])
        category.slug: category.name,
    };
    return Scaffold(
      body: Column(
        children: [
          MusubiTopBar(
            onBack: () => context.canPop()
                ? context.pop()
                : context.go(AppRoutes.settings),
            title: 'Mis alertas',
            titleAtStart: true,
          ),
          Expanded(
            child: switch (searches) {
              AsyncData(value: []) => const EmptyView(
                title: 'No tienes alertas',
                message:
                    'Cuando una búsqueda no tenga resultados, toca «Avísame '
                    'cuando aparezca» y te avisamos al publicarse.',
                icon: MusubiIcons.bell,
              ),
              AsyncData(:final value) => ListView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  MediaQuery.paddingOf(context).bottom + 24,
                ),
                children: [
                  Text(
                    'Te avisamos cuando alguien publique algo con todas las '
                    'palabras. Cada alerta dura 30 días.',
                    style: MusubiType.style(
                      14,
                      line: 20,
                      color: c.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  for (final search in value)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AlertCard(
                        search: search,
                        summary: summary(search, names),
                        onRemove: () =>
                            unawaited(_remove(context, ref, search)),
                      ),
                    ),
                ],
              ),
              AsyncError(:final error) => ErrorView(
                message: error is ApiFailure
                    ? error.message
                    : 'No pudimos cargar tus alertas.',
                onRetry: () => ref.invalidate(mySavedSearchesProvider),
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}

/// Una alerta: campana, lo que se busco, sus filtros, cuando vence y "Quitar".
class _AlertCard extends StatelessWidget {
  const new({
    required this.search,
    required this.summary,
    required this.onRemove,
  });

  final SavedSearch search;
  final String summary;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Container(
      key: Key('alert-${search.id}'),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Row(
        spacing: 12,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.brandSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: MusubiIcon(
                MusubiIcons.bell,
                size: 20,
                strokeWidth: 1.9,
                color: c.brand,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  search.query,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: MusubiType.style(
                    15,
                    weight: FontWeight.w700,
                    line: 20,
                    color: c.textPrimary,
                  ),
                ),
                Text(
                  summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: MusubiType.style(
                    12.5,
                    line: 17,
                    color: c.textSecondary,
                  ),
                ),
                Text(
                  'Vence el ${dayMonth(search.expiresAt.toLocal())}',
                  style: MusubiType.style(
                    12.5,
                    line: 17,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Pressable(
            key: Key('alert-remove-${search.id}'),
            onTap: onRemove,
            semanticLabel: 'Quitar la alerta de ${search.query}',
            builder: (context, pressed) => Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: pressed ? c.surface : null,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  'Quitar',
                  style: MusubiType.style(
                    14,
                    weight: FontWeight.w700,
                    color: c.brand,
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
