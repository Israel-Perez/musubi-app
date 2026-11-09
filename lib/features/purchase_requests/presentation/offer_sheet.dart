import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/session/session_tokens.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/avatars.dart';
import 'package:musubi_app/core/widgets/css_dashes.dart';
import 'package:musubi_app/core/widgets/feedback_views.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_panel.dart';
import 'package:musubi_app/core/widgets/musubi_sheet.dart';
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/core/widgets/shake.dart';
import 'package:musubi_app/core/widgets/skeleton.dart';
import 'package:musubi_app/features/listings/data/photo_picker.dart';
import 'package:musubi_app/features/listings/domain/listing_models.dart';
import 'package:musubi_app/features/listings/presentation/listings_providers.dart';
import 'package:musubi_app/features/marketplace/data/product_json.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/home_cards.dart';
import 'package:musubi_app/features/purchase_requests/domain/offer_models.dart';
import 'package:musubi_app/features/purchase_requests/domain/wanted_models.dart';
import 'package:musubi_app/features/purchase_requests/presentation/wanted_board_cards.dart';
import 'package:musubi_app/features/purchase_requests/presentation/wanted_providers.dart';

/// "Fernanda" de "Fernanda Ortiz": como la nombra la maqueta.
String _firstName(WantedRequest r) => r.requesterName.trim().split(' ').first;

/// "Yo tengo este producto" (HU-16; `Yo-tengo-vincular` y `Yo-tengo-oferta`):
/// hoja que empieza a 90 de arriba. Devuelve la oferta enviada, o `null` si
/// se cierra sin enviar.
Future<WantedOffer?> showOfferSheet(
  BuildContext context,
  WantedRequest request,
) => showModalBottomSheet<WantedOffer>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  elevation: 0,
  barrierColor: context.musubi.scrim,
  sheetAnimationStyle: const AnimationStyle(
    duration: Duration(milliseconds: 420),
    reverseDuration: Duration(milliseconds: 220),
    curve: musubiEaseOut,
  ),
  builder: (_) => OfferSheet(request: request),
);

/// Contenido de la hoja (ver [showOfferSheet]).
class OfferSheet extends ConsumerStatefulWidget {
  const new({required this.request, super.key});

  final WantedRequest request;

  @override
  ConsumerState<OfferSheet> createState() => _OfferSheetState();
}

class _OfferSheetState extends ConsumerState<OfferSheet> {
  final _message = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _priceFocus = FocusNode();

  bool _loading = true;
  List<OwnListing> _listings = const [];
  WantedOffer? _existing;
  OfferKind _kind = OfferKind.direct;
  String? _productId;
  String _condition = 'used';
  String? _photoKey;
  String? _photoUrl;
  bool _uploading = false;
  bool _sending = false;
  bool _priceError = false;
  bool _descriptionError = false;
  int _shake = 0;

  WantedRequest get _request => widget.request;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    _price.addListener(() => setState(() {}));
    _priceFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _message.dispose();
    _description.dispose();
    _price.dispose();
    _priceFocus.dispose();
    super.dispose();
  }

  /// Mis publicaciones disponibles y, si ya ofreci, mi oferta (RN-14).
  Future<void> _load() async {
    final repository = ref.read(wantedRepositoryProvider);
    try {
      // A la vez; si una falla, Future.wait atiende el error de la otra.
      final results = await Future.wait<Object?>([
        ref.read(listingsRepositoryProvider).mine(),
        repository.myOffer(_request.id),
      ]);
      final mine = results[0]! as List<OwnListing>;
      final existing = results[1] as WantedOffer?;
      if (!mounted) return;
      final available = [
        for (final l in mine)
          if (l.status == ListingStatus.active) l,
      ];
      setState(() {
        _listings = available;
        _existing = existing;
        _loading = false;
        if (existing != null) {
          _prefill(existing);
        } else if (available.isNotEmpty) {
          // Con publicaciones, la maqueta abre en "Vincular publicación".
          _kind = OfferKind.listing;
          _productId = available.first.product.id;
        }
      });
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      showMusubiSnack(
        ScaffoldMessenger.of(context),
        failure.message,
        icon: MusubiIcons.circleAlert,
        tone: SnackTone.warn,
      );
      Navigator.of(context).pop();
    }
  }

  void _prefill(WantedOffer offer) {
    _message.text = offer.message ?? '';
    if (offer.kind == OfferKind.listing &&
        _listings.any((l) => l.product.id == offer.productId)) {
      _kind = OfferKind.listing;
      _productId = offer.productId;
      return;
    }
    _kind = OfferKind.direct;
    _description.text = offer.kind == OfferKind.direct ? offer.title : '';
    _price.text = '${offer.priceCents ~/ 100}';
    _condition = offer.condition;
    _photoUrl = offer.kind == OfferKind.direct ? offer.photoUrl : null;
    _photoKey = offer.kind == OfferKind.direct ? offer.photoKey : null;
    if (_listings.isNotEmpty) _productId = _listings.first.product.id;
  }

  int? get _priceCents {
    final pesos = int.tryParse(_price.text);
    return pesos == null || pesos == 0 ? null : pesos * 100;
  }

  Future<void> _pickPhoto() async {
    final messenger = ScaffoldMessenger.of(context);
    final action = await showMusubiPanel<String>(
      context,
      builder: (context) => MusubiPanel(
        title: 'Foto del producto',
        bodyInset: 12,
        child: MusubiOptions<String>(
          plain: true,
          options: [
            const MusubiOption(
              value: 'camera',
              label: 'Tomar foto',
              icon: MusubiIcons.camera,
            ),
            const MusubiOption(
              value: 'gallery',
              label: 'Elegir de la galería',
              icon: MusubiIcons.image,
            ),
            if (_photoUrl != null)
              const MusubiOption(
                value: 'remove',
                label: 'Quitar foto',
                icon: MusubiIcons.trash,
                danger: true,
              ),
          ],
          onPick: (value) => Navigator.of(context).pop(value),
        ),
      ),
    );
    if (action == null || !mounted) return;
    if (action == 'remove') {
      setState(() => _photoKey = _photoUrl = null);
      return;
    }
    try {
      final picker = ref.read(photoPickerProvider);
      final path = action == 'camera'
          ? await picker.takePhoto()
          : (await picker.pickFromGallery(max: 1)).firstOrNull;
      if (path == null || !mounted) return;
      setState(() => _uploading = true);
      final uploaded = await ref
          .read(listingsRepositoryProvider)
          .uploadPhoto(path);
      if (!mounted) return;
      setState(() {
        _photoKey = uploaded.key;
        _photoUrl = uploaded.url;
      });
      showMusubiSnack(messenger, 'Agregaste una foto', icon: MusubiIcons.image);
    } on PhotoPickFailure {
      showMusubiSnack(
        messenger,
        action == 'camera'
            ? 'No pudimos abrir la cámara.'
            : 'No pudimos abrir tu galería.',
        icon: MusubiIcons.circleAlert,
        tone: SnackTone.warn,
      );
    } on ApiFailure catch (failure) {
      showMusubiSnack(
        messenger,
        failure.message,
        icon: MusubiIcons.circleAlert,
        tone: SnackTone.warn,
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _send() async {
    final NewOffer offer;
    if (_kind == OfferKind.listing && _productId != null) {
      offer = NewOffer.listing(productId: _productId!, message: _message.text);
    } else {
      final price = _priceCents;
      final description = _description.text.trim();
      setState(() {
        _priceError = price == null;
        _descriptionError = description.length < 3;
      });
      if (price == null || description.length < 3) {
        setState(() => _shake++);
        return;
      }
      offer = NewOffer.direct(
        description: description,
        priceCents: price,
        condition: _condition,
        photoKey: _photoKey,
      );
    }
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sending = true);
    try {
      final sent = await ref
          .read(wantedRepositoryProvider)
          .sendOffer(_request.id, offer);
      if (!mounted) return;
      Navigator.of(context).pop(sent);
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() => _sending = false);
      showMusubiSnack(
        messenger,
        failure.message,
        icon: MusubiIcons.circleAlert,
        tone: SnackTone.warn,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final media = MediaQuery.of(context);
    final first = _firstName(_request);
    final linking = _kind == OfferKind.listing && _listings.isNotEmpty;
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: Container(
        height: media.size.height - 90 - media.viewInsets.bottom,
        decoration: BoxDecoration(
          color: c.background,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(MusubiSizes.radiusSheet),
          ),
        ),
        child: Semantics(
          scopesRoute: true,
          namesRoute: true,
          label: 'Yo tengo este producto',
          explicitChildNodes: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: c.borderStrong,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              _header(c),
              _RequestCard(request: _request),
              Expanded(
                child: _loading
                    ? const Padding(
                        padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: SkeletonShimmer(
                          child: Column(
                            spacing: 8,
                            children: [
                              SkeletonBox(height: 44, radius: 14),
                              SkeletonBox(height: 78, radius: 16),
                              SkeletonBox(height: 78, radius: 16),
                            ],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Sin publicaciones disponibles, solo la oferta
                            // directa (HU-16).
                            if (_listings.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  12,
                                  20,
                                  0,
                                ),
                                child: _Segmented<OfferKind>(
                                  key: const Key('offer-tabs'),
                                  height: 44,
                                  fontSize: 13.5,
                                  value: _kind,
                                  options: const [
                                    (OfferKind.listing, 'Vincular publicación'),
                                    (OfferKind.direct, 'Oferta directa'),
                                  ],
                                  onChanged: (kind) =>
                                      setState(() => _kind = kind),
                                ),
                              ),
                            if (linking) ..._linkBody(c, first),
                            if (!linking) ..._directBody(c, first),
                          ],
                        ),
                      ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  math.max(30, media.viewPadding.bottom),
                ),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: c.border)),
                ),
                child: MusubiButton(
                  key: const Key('offer-send'),
                  // HU-17: una oferta elegida o rechazada ya no se cambia.
                  label: switch (_existing?.status) {
                    OfferStatus.accepted => '$first eligió tu oferta',
                    OfferStatus.rejected => '$first rechazó tu oferta',
                    OfferStatus.sent => 'Actualizar oferta',
                    null => 'Enviar oferta',
                  },
                  icon: MusubiIcons.send,
                  iconSize: 19,
                  fontSize: 16,
                  loading: _sending,
                  loadingLabel: 'Enviando oferta…',
                  onPressed:
                      _loading ||
                          _uploading ||
                          (_existing?.status ?? OfferStatus.sent) !=
                              OfferStatus.sent
                      ? null
                      : _send,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(MusubiColors c) => Padding(
    padding: const EdgeInsets.only(left: 20, right: 10, top: 4),
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Row(
              spacing: 8,
              children: [
                MusubiIcon(MusubiIcons.hand, size: 22, color: c.brand),
                Flexible(
                  child: Text(
                    'Yo tengo este producto',
                    style: MusubiType.style(
                      20,
                      weight: FontWeight.w800,
                      em: -0.02,
                      color: c.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Pressable(
          key: const Key('offer-close'),
          semanticLabel: 'Cerrar',
          onTap: () => Navigator.of(context).pop(),
          builder: (context, _) => SizedBox.square(
            dimension: MusubiSizes.minTouch,
            child: Center(
              child: MusubiIcon(MusubiIcons.x, size: 22, color: c.textPrimary),
            ),
          ),
        ),
      ],
    ),
  );

  List<Widget> _linkBody(MusubiColors c, String first) => [
    Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Text(
        'Elige una de tus publicaciones. $first verá la foto, el precio y '
        'tu reputación.',
        style: MusubiType.style(13.5, line: 19, color: c.textSecondary),
      ),
    ),
    Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Semantics(
        label: 'Tus publicaciones',
        child: Column(
          spacing: 8,
          children: [
            for (final listing in _listings)
              _ListingChoice(
                listing: listing,
                selected: listing.product.id == _productId,
                // NOTE (HU-18): "Coincide" en la publicacion que encaja.
                onTap: () => setState(() => _productId = listing.product.id),
              ),
          ],
        ),
      ),
    ),
    Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: _Labeled(
        label: 'Mensaje para $first',
        extra: 'Opcional',
        child: _Box(
          child: _area(
            _message,
            key: const Key('offer-message'),
            hint: '¡Hola, $first! Te lo llevo a donde estés en el campus.',
          ),
        ),
      ),
    ),
  ];

  List<Widget> _directBody(MusubiColors c, String first) {
    final price = _priceCents;
    final over = price != null && price > _request.budgetCents;
    return [
      Container(
        margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            MusubiIcon(
              MusubiIcons.info,
              size: 17,
              strokeWidth: 1.9,
              color: c.textPrimary,
            ),
            Expanded(
              child: Text(
                '¿No lo has publicado? No pasa nada. Esta oferta solo la '
                'verá $first.',
                style: MusubiType.style(13, line: 18, color: c.textPrimary),
              ),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 14,
          children: [
            _Labeled(
              label: 'Descripción',
              child: Shake(
                trigger: _descriptionError ? _shake : null,
                child: _Box(
                  error: _descriptionError,
                  child: _area(
                    _description,
                    key: const Key('offer-description'),
                    hint: 'Cómo es, cómo está y qué incluye.',
                    onChanged: (_) {
                      if (_descriptionError) {
                        setState(() => _descriptionError = false);
                      }
                    },
                  ),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Expanded(
                  child: _Labeled(
                    label: 'Precio',
                    child: Shake(
                      trigger: _priceError ? _shake : null,
                      child: _priceBox(c),
                    ),
                  ),
                ),
                Expanded(
                  child: _Labeled(
                    label: 'Estado',
                    child: _Segmented<String>(
                      key: const Key('offer-condition'),
                      height: 52,
                      fontSize: 14,
                      value: _condition,
                      options: const [('new', 'Nuevo'), ('used', 'Usado')],
                      onChanged: (value) => setState(() => _condition = value),
                    ),
                  ),
                ),
              ],
            ),
            if (price != null)
              Transform.translate(
                offset: const Offset(0, -6),
                child: Row(
                  key: const Key('offer-budget-hint'),
                  spacing: 6,
                  children: [
                    MusubiIcon(
                      over ? MusubiIcons.circleAlert : MusubiIcons.check,
                      size: 15,
                      strokeWidth: 2.4,
                      color: over ? c.error : c.successText,
                    ),
                    Expanded(
                      child: Text(
                        over
                            ? 'Está arriba de su presupuesto '
                                  '(${formatPrice(_request.budgetCents)})'
                            : 'Está dentro de su presupuesto '
                                  '(${formatPrice(_request.budgetCents)})',
                        style: MusubiType.style(
                          13,
                          weight: FontWeight.w600,
                          color: over ? c.error : c.successText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              spacing: 14,
              children: [
                _PhotoButton(
                  url: _photoUrl,
                  uploading: _uploading,
                  onTap: _uploading ? null : () => unawaited(_pickPhoto()),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text.rich(
                        TextSpan(
                          text: 'Foto ',
                          children: [
                            TextSpan(
                              text: '· opcional',
                              style: MusubiType.style(
                                14,
                                weight: FontWeight.w600,
                                color: c.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        style: MusubiType.style(
                          14,
                          weight: FontWeight.w700,
                          color: c.textPrimary,
                        ),
                      ),
                      Text(
                        'Una foto real ayuda a que te elijan.',
                        style: MusubiType.style(
                          13,
                          line: 18,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  Widget _priceBox(MusubiColors c) {
    final focused = _priceFocus.hasFocus;
    final border = _priceError
        ? c.error
        : focused
        ? c.brandBorder
        : c.border;
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(MusubiSizes.radiusField),
        border: Border.all(color: border, width: 1.5),
        boxShadow: focused && !_priceError
            ? [BoxShadow(color: c.brandSoft, spreadRadius: 4)]
            : null,
      ),
      child: Row(
        spacing: 4,
        children: [
          Text(
            r'$',
            style: MusubiType.style(
              17,
              weight: FontWeight.w800,
              color: c.textSecondary,
            ),
          ),
          Expanded(
            child: TextField(
              key: const Key('offer-price'),
              controller: _price,
              focusNode: _priceFocus,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              onChanged: (_) {
                if (_priceError) setState(() => _priceError = false);
              },
              cursorColor: c.brand,
              style: MusubiType.style(
                18,
                weight: FontWeight.w800,
                color: c.textPrimary,
              ),
              decoration: const InputDecoration.collapsed(hintText: ''),
            ),
          ),
        ],
      ),
    );
  }

  Widget _area(
    TextEditingController controller, {
    required Key key,
    required String hint,
    ValueChanged<String>? onChanged,
  }) {
    final c = context.musubi;
    final style = MusubiType.style(15, line: 22);
    return TextField(
      key: key,
      controller: controller,
      minLines: 2,
      maxLines: 4,
      maxLength: 300,
      onChanged: onChanged,
      textCapitalization: TextCapitalization.sentences,
      cursorColor: c.brand,
      style: style.copyWith(color: c.textPrimary),
      decoration: InputDecoration.collapsed(
        hintText: hint,
        hintStyle: style.copyWith(color: c.textSecondary),
      ).copyWith(counterText: ''),
    );
  }
}

/// "Fernanda busca · Bata de laboratorio talla M · Hasta $300 · lun 5 oct".
class _RequestCard extends StatelessWidget {
  const new({required this.request});

  final WantedRequest request;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.brandSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        spacing: 12,
        children: [
          ProfileAvatar(
            initials: initialsOf(request.requesterName),
            size: 38,
            fontSize: 13,
            photoUrl: request.requesterPhotoUrl,
            palette:
                (request.requesterId ?? request.requesterName).codeUnits.fold(
                  0,
                  (a, b) => a + b,
                ) %
                5,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 1,
              children: [
                Text(
                  '${_firstName(request)} busca',
                  style: MusubiType.style(
                    12,
                    weight: FontWeight.w700,
                    color: c.textSecondary,
                  ),
                ),
                Text(
                  request.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: MusubiType.style(
                    14.5,
                    weight: FontWeight.w800,
                    color: c.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: 1,
            children: [
              Text(
                'Hasta ${formatPrice(request.budgetCents)}',
                style: MusubiType.style(
                  16,
                  weight: FontWeight.w800,
                  color: c.brandStrongText,
                ),
              ),
              Text(
                wantedDay(request),
                style: MusubiType.style(
                  12,
                  weight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Una de mis publicaciones (`role="radio"`): foto de 54, nombre, precio,
/// estado y el circulo.
class _ListingChoice extends StatelessWidget {
  const new({
    required this.listing,
    required this.selected,
    required this.onTap,
  });

  final OwnListing listing;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final product = listing.product;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      child: Pressable(
        key: ValueKey('offer-listing-${product.id}'),
        semanticLabel: product.title,
        onTap: onTap,
        builder: (context, _) => AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? c.brand : c.border,
              width: selected ? 2 : 1.5,
            ),
          ),
          child: Row(
            spacing: 12,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox.square(
                  dimension: 54,
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
                        14,
                        weight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                    Row(
                      spacing: 8,
                      children: [
                        Text(
                          formatPrice(product.priceCents),
                          style: MusubiType.style(
                            12.5,
                            weight: FontWeight.w800,
                            color: c.textPrimary,
                          ),
                        ),
                        Text(
                          product.condition ?? '',
                          style: MusubiType.style(
                            12.5,
                            weight: FontWeight.w600,
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? c.brand : c.neutralStrong,
                    width: 2,
                  ),
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: c.brand,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Etiqueta de 13 sobre el campo, con "Opcional" a un lado.
class _Labeled extends StatelessWidget {
  const new({required this.label, required this.child, this.extra});

  final String label;
  final String? extra;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          spacing: 6,
          children: [
            Flexible(
              child: Text(
                label,
                style: MusubiType.style(
                  13,
                  weight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
            ),
            if (extra != null)
              Text(
                extra!,
                style: MusubiType.style(
                  12,
                  weight: FontWeight.w600,
                  color: c.textSecondary,
                ),
              ),
          ],
        ),
        child,
      ],
    );
  }
}

/// Caja de texto de la hoja: radio 14, borde de 1.5 y relleno `10 14`.
class _Box extends StatelessWidget {
  const new({required this.child, this.error = false});

  final Widget child;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(MusubiSizes.radiusField),
        border: Border.all(color: error ? c.error : c.border, width: 1.5),
      ),
      child: child,
    );
  }
}

/// Selector de dos opciones (`role="tablist"` y "Nuevo/Usado"): fondo gris
/// con relleno de 3 y la elegida en blanco con sombra.
class _Segmented<T> extends StatelessWidget {
  const new({
    required this.value,
    required this.options,
    required this.onChanged,
    required this.height,
    required this.fontSize,
    super.key,
  });

  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Container(
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(MusubiSizes.radiusField),
      ),
      child: Row(
        spacing: 3,
        children: [
          for (final (option, label) in options)
            Expanded(
              child: Semantics(
                selected: option == value,
                button: true,
                child: Pressable(
                  key: ValueKey('segment-$option'),
                  semanticLabel: label,
                  onTap: () => onChanged(option),
                  builder: (context, _) => AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: option == value ? c.background : null,
                      borderRadius: BorderRadius.circular(11),
                      boxShadow: option == value
                          ? const [
                              BoxShadow(
                                color: Color(0x1F1C1C1E),
                                offset: Offset(0, 1),
                                blurRadius: 3,
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MusubiType.style(
                        fontSize,
                        weight: option == value
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: option == value
                            ? c.textPrimary
                            : c.textSecondary,
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

/// Cuadro de 72 con borde punteado y la camara, o la foto elegida.
class _PhotoButton extends StatelessWidget {
  const new({required this.url, required this.uploading, this.onTap});

  final String? url;
  final bool uploading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Pressable(
      key: const Key('offer-photo'),
      semanticLabel: url == null
          ? 'Agregar una foto (opcional)'
          : 'Cambiar la foto',
      onTap: onTap,
      builder: (context, pressed) => SizedBox.square(
        dimension: 72,
        child: url != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ProductPhoto(url: url),
              )
            : CustomPaint(
                foregroundPainter: CssDashedBorderPainter(
                  color: c.neutralStrong,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: pressed ? c.surface : null,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: uploading
                        ? SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: c.brand,
                            ),
                          )
                        : MusubiIcon(
                            MusubiIcons.camera,
                            strokeWidth: 1.9,
                            color: c.brandText,
                          ),
                  ),
                ),
              ),
      ),
    );
  }
}

/// "¡Oferta enviada!" (`Yo-tengo-enviada`): la palomita, lo que se ofrecio y
/// "Ir a mensajes" o "Seguir viendo solicitudes".
Future<void> showOfferSentSheet(
  BuildContext context, {
  required WantedRequest request,
  required WantedOffer offer,
}) => showMusubiSheet<void>(
  context,
  style: MusubiSheetStyle.screen,
  builder: (context) => _OfferSent(request: request, offer: offer),
);

class _OfferSent extends StatelessWidget {
  const new({required this.request, required this.offer});

  final WantedRequest request;
  final WantedOffer offer;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final linked = offer.kind == OfferKind.listing;
    return Column(
      key: const Key('offer-sent'),
      children: [
        const SizedBox(height: 22),
        SizedBox.square(
          dimension: 76,
          child: Stack(
            children: [
              PopIn(
                delay: const Duration(milliseconds: 150),
                child: Container(
                  decoration: BoxDecoration(
                    color: c.successSoft,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Center(
                child: RiseIn(
                  delay: const Duration(milliseconds: 300),
                  duration: const Duration(milliseconds: 600),
                  child: MusubiIcon(
                    MusubiIcons.send,
                    size: 34,
                    color: c.success,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Semantics(
          header: true,
          liveRegion: true,
          child: Text(
            '¡Oferta enviada!',
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
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 310),
          child: Text(
            // NOTE (HU-30): el aviso a quien busca llega con las
            // notificaciones; mientras, ve la oferta en "Mis solicitudes".
            'Le avisamos a ${_firstName(request)}. Si le interesa, te '
            'escribirá por el chat y te avisaremos.',
            textAlign: TextAlign.center,
            style: MusubiType.style(15, line: 22, color: c.textSecondary),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 18),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.border),
          ),
          child: Row(
            spacing: 12,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox.square(
                  dimension: 56,
                  child: ProductPhoto(
                    url: offer.photoUrl ?? categoryPhoto(request.categorySlug),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      linked ? offer.title : request.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: MusubiType.style(
                        14,
                        weight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                    Text(
                      linked ? 'Vinculada a tu publicación' : 'Oferta directa',
                      style: MusubiType.style(
                        12.5,
                        weight: FontWeight.w600,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formatPrice(offer.priceCents),
                style: MusubiType.style(
                  17,
                  weight: FontWeight.w800,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        MusubiButton(
          key: const Key('offer-sent-messages'),
          label: 'Ir a mensajes',
          fontSize: 16,
          onPressed: () {
            final router = GoRouter.of(context);
            Navigator.of(context).pop();
            router.go(AppRoutes.messages);
          },
        ),
        const SizedBox(height: 6),
        Pressable(
          key: const Key('offer-sent-close'),
          semanticLabel: 'Seguir viendo solicitudes',
          onTap: () => Navigator.of(context).pop(),
          builder: (context, _) => SizedBox(
            height: MusubiSizes.minTouch,
            child: Center(
              child: Text(
                'Seguir viendo solicitudes',
                style: MusubiType.style(
                  14,
                  weight: FontWeight.w700,
                  color: c.brandText,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
