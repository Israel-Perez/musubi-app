import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/home_cards.dart';
import 'package:musubi_app/features/purchase_requests/domain/wanted_models.dart';
import 'package:musubi_app/features/purchase_requests/presentation/need_widgets.dart';
import 'package:musubi_app/features/purchase_requests/presentation/wanted_providers.dart';

/// `Necesidad-publicada` (HU-13): la solicitud activa y lo que ya coincide en
/// el campus (busqueda HU-09), lo que cabe en el presupuesto primero.
/// NOTE (HU-16): el aviso "Diego tiene lo que buscas" llega con las ofertas.
class NeedDoneScreen extends ConsumerWidget {
  const new({required this.request, super.key});

  final WantedRequest? request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.musubi;
    final wanted = request;
    final bottom = math.max(30, MediaQuery.viewPaddingOf(context).bottom + 6);
    final matches = <ProductSummary>[];
    if (wanted != null) {
      final budget = wanted.budgetCents;
      matches
        ..addAll(ref.watch(needMatchesProvider(wanted.title)).value ?? const [])
        // Lo que cabe en el presupuesto primero, del mas barato al mas caro.
        ..sort((a, b) {
          final inA = a.priceCents <= budget ? 0 : 1;
          final inB = b.priceCents <= budget ? 0 : 1;
          return inA != inB ? inA - inB : a.priceCents - b.priceCents;
        });
    }
    final shown = matches.take(3).toList();

    return Scaffold(
      backgroundColor: c.background,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Pressable(
                  onTap: () => context.go(AppRoutes.home),
                  semanticLabel: 'Cerrar',
                  builder: (context, _) => SizedBox.square(
                    dimension: MusubiSizes.minTouch,
                    child: Center(
                      child: MusubiIcon(
                        MusubiIcons.x,
                        size: 22,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 12,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: c.success,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: MusubiIcon(
                            MusubiIcons.check,
                            strokeWidth: 2.8,
                            color: Color(0xFFFFFFFF),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 4,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                '¡Tu solicitud está publicada!',
                                style: MusubiType.style(
                                  24,
                                  weight: FontWeight.w800,
                                  line: 30,
                                  em: -0.025,
                                  color: c.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              'Avisamos a quienes podrían tenerla. Te '
                              'avisaremos en cuanto alguien responda.',
                              style: MusubiType.style(
                                14.5,
                                line: 21,
                                color: c.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (wanted != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: WantedPreviewCard(
                      title: wanted.title,
                      budgetCents: wanted.budgetCents,
                      dateCaption: 'Lo necesitas',
                      when: wanted.neededBy == null
                          ? 'Sin fecha'
                          : shortDate(wanted.neededBy!),
                      published: true,
                    ),
                  ),
                if (wanted != null && shown.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      spacing: 8,
                      children: [
                        Flexible(
                          child: Text(
                            'Ya coinciden con lo que buscas',
                            style: MusubiType.style(
                              18,
                              weight: FontWeight.w800,
                              line: 24,
                              em: -0.02,
                              color: c.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          constraints: const BoxConstraints(minWidth: 24),
                          height: 24,
                          padding: const EdgeInsets.symmetric(horizontal: 7),
                          decoration: BoxDecoration(
                            color: c.inverse,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${matches.length}',
                            style: MusubiType.style(
                              12,
                              weight: FontWeight.w800,
                              color: const Color(0xFFFFFFFF),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      spacing: 10,
                      children: [
                        for (final product in shown)
                          _MatchRow(
                            product: product,
                            inBudget: product.priceCents <= wanted.budgetCents,
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: c.background,
              border: Border(top: BorderSide(color: c.border)),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, bottom.toDouble()),
              child: Row(
                spacing: 10,
                children: [
                  SizedBox(
                    width: 112,
                    child: MusubiButton(
                      label: 'Inicio',
                      kind: MusubiButtonKind.secondary,
                      onPressed: () => context.go(AppRoutes.home),
                    ),
                  ),
                  Expanded(
                    child: MusubiButton(
                      key: const Key('need-see-mine'),
                      label: 'Ver mi solicitud',
                      onPressed: () => context.go(AppRoutes.myWanted),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Una publicacion que coincide: foto de 64, nombre · estado, quien vende,
/// "Dentro de tu presupuesto" o "Modelo parecido", precio y flecha.
class _MatchRow extends StatelessWidget {
  const new({required this.product, required this.inBudget});

  final ProductSummary product;
  final bool inBudget;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final title = [product.title, ?product.condition].join(' · ');
    return Pressable(
      onTap: () => unawaited(context.push(AppRoutes.product(product.id))),
      semanticLabel: '$title, ${formatPrice(product.priceCents)}',
      builder: (context, pressed) => Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
        decoration: BoxDecoration(
          color: pressed ? c.surface : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border),
        ),
        child: Row(
          spacing: 12,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox.square(
                dimension: 64,
                child: ProductPhoto(url: product.photoUrl),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MusubiType.style(
                      14,
                      weight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                  if (product.sellerName case final seller?)
                    Text(
                      [
                        seller,
                        if (product.sellerRating case final rating?)
                          '★ ${rating.toStringAsFixed(1)}',
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MusubiType.style(
                        12.5,
                        weight: FontWeight.w600,
                        color: c.textSecondary,
                      ),
                    ),
                  Row(
                    spacing: 4,
                    children: [
                      MusubiIcon(
                        inBudget ? MusubiIcons.check : MusubiIcons.info,
                        size: 13,
                        strokeWidth: inBudget ? 2.6 : 2,
                        color: inBudget ? c.successText : c.textSecondary,
                      ),
                      Flexible(
                        child: Text(
                          inBudget
                              ? 'Dentro de tu presupuesto'
                              : 'Arriba de tu presupuesto',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: MusubiType.style(
                            12,
                            weight: FontWeight.w700,
                            color: inBudget ? c.successText : c.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                formatPrice(product.priceCents),
                style: MusubiType.style(
                  17,
                  weight: FontWeight.w800,
                  color: c.textPrimary,
                  tabular: true,
                ),
              ),
            ),
            MusubiIcon(
              MusubiIcons.chevronRight,
              size: 18,
              color: c.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
