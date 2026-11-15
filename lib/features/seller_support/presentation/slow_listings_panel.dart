import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_panel.dart';
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/features/listings/domain/listing_models.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/home_cards.dart';
import 'package:musubi_app/features/purchase_requests/domain/wanted_models.dart';
import 'package:musubi_app/features/purchase_requests/presentation/offer_sheet.dart';
import 'package:musubi_app/features/purchase_requests/presentation/wanted_providers.dart';
import 'package:musubi_app/features/seller_support/domain/seller_support.dart';
import 'package:musubi_app/features/seller_support/presentation/seller_support_providers.dart';

/// Tarjetas que se ven antes de "Ver los N".
const int slowCardsShown = 3;

/// "Calculadora científica Casio" → "calculadora"; `null` si la primera
/// palabra no se lee bien ("TI-84", "2 libros"). Igual que el aviso de la API.
String? shortName(String title) {
  final first = title
      .trim()
      .split(RegExp(r'\s+'))
      .first
      .replaceAll(RegExp(r'[,.:;]+$'), '');
  if (first.length < 3 || !RegExp(r'^\p{L}+$', unicode: true).hasMatch(first)) {
    return null;
  }
  final capitalized =
      first[0] == first[0].toUpperCase() &&
      first[1] == first[1].toLowerCase() &&
      first[1] != first[1].toUpperCase();
  return capitalized ? first[0].toLowerCase() + first.substring(1) : first;
}

String _students(int people, {required String one, required String many}) =>
    people == 1 ? '1 estudiante $one' : '$people estudiantes $many';

/// "Editar publicación" (HU-37): con [ideas], con el nombre y la descripción de
/// la IA ya escritos.
typedef EditListing = void Function(OwnListing listing, [ListingIdeas? ideas]);

/// "Llevan tiempo sin venderse" (maqueta `Mis-productos`, HU-36/37/38;
/// decision de la usuaria del 15-Nov-2026: una tarjeta por producto). Al
/// tocar una tarjeta, "Ideas para vender más rápido" (HU-37); al tocar
/// "N estudiantes la buscan", "Quienes la buscan" (HU-38).
class SlowListingsPanel extends StatefulWidget {
  const new({required this.slow, required this.onEdit, super.key});

  final SlowListings slow;

  /// "Editar publicación" desde las ideas.
  final EditListing onEdit;

  @override
  State<SlowListingsPanel> createState() => _SlowListingsPanelState();
}

class _SlowListingsPanelState extends State<SlowListingsPanel> {
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final items = widget.slow.items;
    final weeks = (widget.slow.thresholdDays / 7).round();
    final shown = _all ? items : items.take(slowCardsShown).toList();
    return Semantics(
      container: true,
      child: Container(
        key: const Key('slow-listings'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.warningSoft,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Row(
              spacing: 10,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: c.elevated,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  alignment: Alignment.center,
                  child: MusubiIcon(
                    MusubiIcons.trendingDown,
                    size: 19,
                    color: c.warningText,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          'Llevan tiempo sin venderse',
                          style: MusubiType.style(
                            16,
                            weight: FontWeight.w800,
                            line: 21,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        items.length == 1
                            ? '1 producto con más de $weeks semanas'
                            : '${items.length} productos con más de '
                                  '$weeks semanas',
                        style: MusubiType.style(
                          12.5,
                          weight: FontWeight.w600,
                          color: c.warningText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            for (final item in shown)
              _SlowCard(
                item: item,
                onTap: () => unawaited(
                  showSalesTipsSheet(context, item, onEdit: widget.onEdit),
                ),
              ),
            if (!_all && items.length > slowCardsShown)
              Pressable(
                key: const Key('slow-listings-all'),
                onTap: () => setState(() => _all = true),
                semanticLabel: 'Ver los ${items.length}',
                builder: (context, _) => SizedBox(
                  height: MusubiSizes.minTouch,
                  child: Center(
                    child: Text(
                      'Ver los ${items.length}',
                      style: MusubiType.style(
                        14,
                        weight: FontWeight.w800,
                        color: c.warningText,
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

/// La tarjeta blanca: foto de 60, nombre, "$250 · Publicada hace 34 días",
/// vistas y mensajes; abajo, "3 estudiantes la buscan · Ofrécesela".
class _SlowCard extends StatelessWidget {
  const new({required this.item, required this.onTap});

  final SlowListing item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final product = item.listing.product;
    final days = item.daysListed == 1
        ? 'Publicada hace 1 día'
        : 'Publicada hace ${item.daysListed} días';
    final views = item.views == 1 ? '1 vista' : '${item.views} vistas';
    final messages = item.messages == 1
        ? '1 mensaje'
        : '${item.messages} mensajes';
    final stat = MusubiType.style(
      12,
      weight: FontWeight.w600,
      color: c.textSecondary,
    );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.elevated,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x148F5B00),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Pressable(
            key: Key('slow-${product.id}'),
            onTap: onTap,
            semanticLabel:
                '${product.title}, ${formatPrice(product.priceCents)}, '
                '$days, $views, $messages. Ideas para vender más rápido',
            builder: (context, _) => Row(
              spacing: 12,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox.square(
                    dimension: 60,
                    child: ProductPhoto(url: product.photoUrl),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(
                        product.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: MusubiType.style(
                          14.5,
                          weight: FontWeight.w800,
                          color: c.textPrimary,
                        ),
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: formatPrice(product.priceCents),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: c.textPrimary,
                              ),
                            ),
                            TextSpan(text: ' · $days'),
                          ],
                        ),
                        style: MusubiType.style(
                          12.5,
                          weight: FontWeight.w600,
                          color: c.textSecondary,
                        ),
                      ),
                      Wrap(
                        spacing: 10,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            spacing: 4,
                            children: [
                              MusubiIcon(
                                MusubiIcons.eye,
                                size: 13,
                                color: c.textSecondary,
                              ),
                              Text(views, style: stat),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            spacing: 4,
                            children: [
                              MusubiIcon(
                                MusubiIcons.messageCircle,
                                size: 13,
                                color: c.textSecondary,
                              ),
                              Text(messages, style: stat),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (item.people > 0)
            Consumer(
              builder: (context, ref, _) => _DemandLink(
                key: Key('slow-demand-${product.id}'),
                people: item.people,
                onTap: () =>
                    unawaited(showDemandSheet(context, ref, item.listing)),
              ),
            ),
        ],
      ),
    );
  }
}

/// "3 estudiantes la buscan · Ofrécesela" (fondo rojo claro, icono rojo).
class _DemandLink extends StatelessWidget {
  const new({required this.people, required this.onTap, super.key});

  final int people;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final label = _students(people, one: 'la busca', many: 'la buscan');
    return Pressable(
      onTap: onTap,
      semanticLabel: '$label. Ofrécesela',
      builder: (context, _) => Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
        decoration: BoxDecoration(
          color: c.brandSoft,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          spacing: 10,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: c.brand,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: MusubiIcon(MusubiIcons.users, size: 17, color: c.onBrand),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: MusubiType.style(
                      14,
                      weight: FontWeight.w800,
                      color: c.textPrimary,
                    ),
                  ),
                  Text(
                    'Ofrécesela',
                    style: MusubiType.style(
                      12,
                      weight: FontWeight.w600,
                      color: c.brandStrongText,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: MusubiIcon(
                MusubiIcons.chevronRight,
                size: 18,
                strokeWidth: 2.2,
                color: c.brandStrongText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Ideas para vender más rápido" (HU-37; decision de la usuaria del
/// 15-Nov-2026: una hoja al tocar la tarjeta). Son las tres de la API, primero
/// las que aplican; solo orientan (RN-38).
Future<void> showSalesTipsSheet(
  BuildContext context,
  SlowListing item, {
  required EditListing onEdit,
}) async {
  final edit = await showMusubiPanel<({ListingIdeas? ideas})>(
    context,
    builder: (context) => _TipsPanel(item: item),
  );
  if (edit != null) onEdit(item.listing, edit.ideas);
}

class _TipsPanel extends ConsumerStatefulWidget {
  const new({required this.item});

  final SlowListing item;

  @override
  ConsumerState<_TipsPanel> createState() => _TipsPanelState();
}

class _TipsPanelState extends ConsumerState<_TipsPanel> {
  bool _asking = false;
  ListingIdeas? _ideas;
  String? _error;

  /// "Proponer con IA": solo a peticion (RNF-06). Si falla, quedan las ideas
  /// predefinidas y el mensaje de la API (RNF-15).
  Future<void> _ask() async {
    setState(() {
      _asking = true;
      _error = null;
    });
    try {
      final ideas = await ref
          .read(sellerSupportRepositoryProvider)
          .ideas(widget.item.listing.product.id);
      if (!mounted) return;
      setState(() {
        _asking = false;
        _ideas = ideas;
      });
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _asking = false;
        _error = failure.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final item = widget.item;
    return MusubiPanel(
      key: const Key('slow-tips'),
      title: 'Ideas para vender más rápido',
      bodyInset: 20,
      actions: [
        MusubiButton(
          key: const Key('slow-tips-edit'),
          label: 'Editar publicación',
          icon: MusubiIcons.pencil,
          onPressed: () => Navigator.of(context).pop((ideas: null)),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          Text(
            '«${item.listing.product.title}» lleva ${item.daysListed} días '
            'publicada sin venderse.',
            style: MusubiType.style(14, line: 20, color: c.textSecondary),
          ),
          for (final tip in item.tips) _TipRow(tip: tip),
          _AiIdeas(
            asking: _asking,
            ideas: _ideas,
            error: _error,
            onAsk: () => unawaited(_ask()),
            onUse: (ideas) => Navigator.of(context).pop((ideas: ideas)),
          ),
          Text(
            'Son ideas: tú decides qué cambiar. Musubi nunca cambia tu '
            'publicación por su cuenta.',
            style: MusubiType.style(
              12.5,
              weight: FontWeight.w600,
              line: 17,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Nombre y descripción con IA" (HU-37): pide la propuesta, la muestra y
/// "Usar en mi publicación" abre la edición con ella (RN-38: quien vende
/// guarda).
class _AiIdeas extends StatelessWidget {
  const new({
    required this.asking,
    required this.ideas,
    required this.error,
    required this.onAsk,
    required this.onUse,
  });

  final bool asking;
  final ListingIdeas? ideas;
  final String? error;
  final VoidCallback onAsk;
  final ValueChanged<ListingIdeas> onUse;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final proposal = ideas;
    return Container(
      key: const Key('slow-ai'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c.inverse,
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: MusubiIcon(
                  MusubiIcons.sparkle,
                  size: 18,
                  color: c.onBrand,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      'Nombre y descripción con IA',
                      style: MusubiType.style(
                        15,
                        weight: FontWeight.w800,
                        color: c.textPrimary,
                      ),
                    ),
                    Text(
                      proposal == null
                          ? 'Te proponemos un texto más claro con lo que '
                                'buscan los demás. Solo enviamos tu '
                                'publicación, sin tu nombre ni tus datos.'
                          : 'Revísalo antes de usarlo: tú decides qué se '
                                'queda.',
                      style: MusubiType.style(
                        13.5,
                        line: 19,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (proposal != null) ...[
            _Proposal(
              key: const Key('slow-ai-title'),
              label: 'Nombre',
              text: proposal.title,
            ),
            _Proposal(
              key: const Key('slow-ai-description'),
              label: 'Descripción',
              text: proposal.description,
            ),
            MusubiButton(
              key: const Key('slow-ai-use'),
              label: 'Usar en mi publicación',
              kind: MusubiButtonKind.secondary,
              icon: MusubiIcons.pencil,
              onPressed: () => onUse(proposal),
            ),
          ] else ...[
            if (error case final message?)
              Text(
                message,
                key: const Key('slow-ai-error'),
                style: MusubiType.style(
                  13,
                  weight: FontWeight.w600,
                  line: 18,
                  color: c.warningText,
                ),
              ),
            MusubiButton(
              key: const Key('slow-ai-ask'),
              label: error == null ? 'Proponer con IA' : 'Intentar de nuevo',
              kind: MusubiButtonKind.secondary,
              icon: MusubiIcons.sparkle,
              loading: asking,
              loadingLabel: 'Proponiendo…',
              onPressed: asking ? null : onAsk,
            ),
          ],
        ],
      ),
    );
  }
}

/// Un campo de la propuesta: la etiqueta y el texto sobre fondo blanco.
class _Proposal extends StatelessWidget {
  const new({required this.label, required this.text, super.key});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.elevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 2,
        children: [
          Text(
            label,
            style: MusubiType.style(
              12,
              weight: FontWeight.w700,
              color: c.textSecondary,
            ),
          ),
          Text(
            text,
            style: MusubiType.style(14, line: 20, color: c.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  const new({required this.tip});

  final SalesTip tip;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final icon = switch (tip.kind) {
      SalesTipKind.price => MusubiIcons.tag,
      SalesTipKind.description => MusubiIcons.fileText,
      SalesTipKind.photos => MusubiIcons.camera,
    };
    return Semantics(
      container: true,
      label: tip.applies ? '${tip.title}. Te lo recomendamos' : tip.title,
      child: Row(
        key: Key('slow-tip-${tip.kind.name}'),
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tip.applies ? c.warningSoft : c.surface,
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: MusubiIcon(
              icon,
              size: 18,
              color: tip.applies ? c.warningText : c.textSecondary,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  tip.title,
                  style: MusubiType.style(
                    15,
                    weight: FontWeight.w800,
                    color: c.textPrimary,
                  ),
                ),
                Text(
                  tip.body,
                  style: MusubiType.style(
                    13.5,
                    line: 19,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Quienes la buscan" (HU-38): las solicitudes "Se busca" que coinciden, con
/// "Yo tengo este producto" (HU-16), y cuantas personas mas tienen una alerta
/// (RN-37: nunca quienes).
Future<void> showDemandSheet(
  BuildContext context,
  WidgetRef ref,
  OwnListing listing,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final requestId = await showMusubiPanel<String>(
    context,
    builder: (context) => _DemandPanel(productId: listing.product.id),
  );
  if (requestId == null || !context.mounted) return;
  final WantedRequest request;
  try {
    request = await ref.read(wantedRepositoryProvider).get(requestId);
  } on ApiFailure catch (failure) {
    showMusubiSnack(
      messenger,
      failure.code == 'wanted.not_found'
          ? 'Esta solicitud ya no está activa.'
          : failure.message,
      icon: MusubiIcons.circleAlert,
      tone: SnackTone.warn,
    );
    ref.invalidate(productDemandProvider(listing.product.id));
    return;
  }
  if (!context.mounted) return;
  final offer = await showOfferSheet(context, request);
  if (offer == null || !context.mounted) return;
  await showOfferSentSheet(context, request: request, offer: offer);
}

class _DemandPanel extends ConsumerWidget {
  const new({required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.musubi;
    final demand = ref.watch(productDemandProvider(productId));
    final note = MusubiType.style(13, line: 18, color: c.textSecondary);
    return MusubiPanel(
      key: const Key('demand-panel'),
      title: 'Quienes la buscan',
      bodyInset: 20,
      child: switch (demand) {
        AsyncData(:final value) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            if (value.requests.isNotEmpty)
              Text(
                'Ofrécesela con “Yo tengo este producto”: le llega tu oferta '
                'al momento.',
                style: note,
              ),
            for (final request in value.requests) _RequestRow(request: request),
            if (value.alerts > 0)
              Text(
                key: const Key('demand-alerts'),
                value.requests.isEmpty
                    ? _alerts(value.alerts, first: true)
                    : _alerts(value.alerts, first: false),
                style: note,
              ),
            if (value.people == 0)
              Text('Por ahora nadie la está buscando.', style: note),
          ],
        ),
        AsyncError(:final error) => Text(
          error is ApiFailure
              ? error.message
              : 'No pudimos ver quién la busca. Inténtalo de nuevo.',
          style: note,
        ),
        _ => Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: c.brand,
              ),
            ),
          ),
        ),
      },
    );
  }

  static String _alerts(int alerts, {required bool first}) {
    final who = alerts == 1
        ? (first ? '1 persona tiene' : 'Y 1 persona más tiene')
        : (first ? '$alerts personas tienen' : 'Y $alerts personas más tienen');
    return '$who una alerta que coincide con tu producto. Por privacidad, no '
        'te decimos quiénes.';
  }
}

class _RequestRow extends StatelessWidget {
  const new({required this.request});

  final DemandRequest request;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final who = [
      if (request.requesterName.isNotEmpty) request.requesterName,
      'Hasta ${formatPrice(request.budgetCents)}',
      'Vence el ${dayMonth(request.expiresAt.toLocal())}',
    ].join(' · ');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Text(
                request.title,
                style: MusubiType.style(
                  15,
                  weight: FontWeight.w800,
                  color: c.textPrimary,
                ),
              ),
              Text(
                who,
                style: MusubiType.style(
                  12.5,
                  weight: FontWeight.w600,
                  color: c.textSecondary,
                ),
              ),
            ],
          ),
          MusubiButton(
            key: Key('demand-offer-${request.id}'),
            label: 'Yo tengo este producto',
            height: MusubiSizes.buttonHeightSmall,
            onPressed: () => Navigator.of(context).pop(request.id),
          ),
        ],
      ),
    );
  }
}

/// `Vender-listo`: "2 estudiantes buscan algo similar · Ofréceles tu
/// calculadora directo con “Yo tengo este producto” y vende más rápido." con
/// "Ver solicitudes" (HU-38). Solo si hay solicitudes a las que ofrecer.
class PublishedDemandCard extends ConsumerWidget {
  const new({required this.product, super.key});

  final ProductSummary product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demand = ref.watch(productDemandProvider(product.id)).value;
    if (demand == null || demand.requests.isEmpty) {
      return const SizedBox.shrink();
    }
    final c = context.musubi;
    final name = shortName(product.title);
    final title = _students(
      demand.people,
      one: 'busca algo similar',
      many: 'buscan algo similar',
    );
    final offer = demand.people == 1 ? 'Ofrécele' : 'Ofréceles';
    return Container(
      key: const Key('published-demand'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.brandSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                child: MusubiIcon(
                  MusubiIcons.megaphone,
                  size: 21,
                  strokeWidth: 1.9,
                  color: c.onBrand,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 3,
                  children: [
                    Text(
                      title,
                      style: MusubiType.style(
                        15.5,
                        weight: FontWeight.w800,
                        color: c.textPrimary,
                      ),
                    ),
                    Text(
                      '$offer tu ${name ?? 'producto'} directo con “Yo tengo '
                      'este producto” y vende más rápido.',
                      style: MusubiType.style(
                        13.5,
                        line: 19,
                        color: c.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          MusubiButton(
            key: const Key('published-demand-see'),
            label: 'Ver solicitudes',
            height: MusubiSizes.buttonHeightSmall,
            trailingIcon: MusubiIcons.arrowRight,
            onPressed: () => unawaited(
              showDemandSheet(
                context,
                ref,
                OwnListing(product: product, status: ListingStatus.active),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
