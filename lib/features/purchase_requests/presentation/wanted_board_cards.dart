import 'package:flutter/material.dart';
import 'package:musubi_app/core/session/session_tokens.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/avatars.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/home_cards.dart';
import 'package:musubi_app/features/purchase_requests/domain/wanted_models.dart';

// Boletos del tablero "Se busca" (HU-15, RNF-19): una solicitud se ve como
// boleto (fondo rojo claro, linea punteada con muescas y presupuesto al
// frente), distinta de la foto grande de un producto.

/// Pareja de colores de las iniciales: la misma persona, el mismo color.
int _palette(WantedRequest r) =>
    (r.requesterId ?? r.requesterName).codeUnits.fold(0, (a, b) => a + b) % 5;

/// "Ing. Software · hace 20 min · 2 ofertas" (`whenText` de la maqueta).
String wantedMeta(WantedRequest r, DateTime now, {bool career = true}) => [
  if (career && r.requesterCareer != null) r.requesterCareer!,
  timeAgo(r.createdAt, now),
  if (r.offersCount > 0)
    '${r.offersCount} ${r.offersCount == 1 ? 'oferta' : 'ofertas'}',
].join(' · ');

/// "lun 5 oct", o "Sin fecha" si no la eligio.
String wantedDay(WantedRequest r) =>
    r.neededBy == null ? 'Sin fecha' : shortDate(r.neededBy!);

/// Boleto de `Se-busca` (con sesion): quien busca con su carrera, la
/// pastilla "SE BUSCA", el producto, Presupuesto · Para el · Categoría y
/// "Yo tengo este producto".
class WantedBoardCard extends StatelessWidget {
  const new({
    required this.request,
    required this.now,
    required this.onOffer,
    super.key,
  });

  final WantedRequest request;
  final DateTime now;
  final VoidCallback onOffer;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final caption = MusubiType.style(
      10.5,
      weight: FontWeight.w700,
      em: 0.05,
      color: c.textSecondary,
    );
    Widget cell(String label, Widget value, {bool end = false}) => Column(
      crossAxisAlignment: end
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label.toUpperCase(), style: caption),
        value,
      ],
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: c.brandSoft,
        borderRadius: BorderRadius.circular(MusubiSizes.radiusWanted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Row(
            spacing: 10,
            children: [
              ProfileAvatar(
                initials: initialsOf(request.requesterName),
                size: 34,
                fontSize: 12,
                photoUrl: request.requesterPhotoUrl,
                palette: _palette(request),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      spacing: 4,
                      children: [
                        Flexible(
                          child: Text(
                            request.requesterName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: MusubiType.style(
                              13.5,
                              weight: FontWeight.w800,
                              color: c.textPrimary,
                            ),
                          ),
                        ),
                        const VerifiedBadge(size: 14),
                      ],
                    ),
                    Text(
                      wantedMeta(request, now),
                      style: MusubiType.style(
                        12,
                        weight: FontWeight.w600,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const WantedTag(),
            ],
          ),
          Text(
            request.title,
            style: MusubiType.style(
              17,
              weight: FontWeight.w800,
              line: 22,
              em: -0.01,
              color: c.textPrimary,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 2),
            child: TicketSeparator(),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: 8,
            children: [
              Expanded(
                child: cell(
                  'Presupuesto',
                  // Con letra muy grande el precio se reduce antes que
                  // desbordar.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatPrice(request.budgetCents),
                      style: MusubiType.style(
                        24,
                        weight: FontWeight.w800,
                        line: 30,
                        em: -0.02,
                        color: c.brandStrongText,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: cell(
                    'Para el',
                    Text(
                      wantedDay(request),
                      maxLines: 1,
                      style: MusubiType.style(
                        14,
                        weight: FontWeight.w800,
                        line: 22,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: cell(
                  'Categoría',
                  Text(
                    request.categoryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: MusubiType.style(
                      14,
                      weight: FontWeight.w700,
                      line: 22,
                      color: c.textPrimary,
                    ),
                  ),
                  end: true,
                ),
              ),
            ],
          ),
          // NOTE (HU-18): "Coincide con tu …" cuando una publicacion propia
          // encaja con la solicitud.
          MusubiButton(
            label: 'Yo tengo este producto',
            height: 48,
            fontSize: 15,
            icon: MusubiIcons.hand,
            iconSize: 19,
            onPressed: onOffer,
          ),
        ],
      ),
    );
  }
}

/// Pastilla roja "SE BUSCA" con el megafono.
class WantedTag extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: c.brand,
        borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          MusubiIcon(
            MusubiIcons.megaphone,
            size: 12,
            strokeWidth: 2.4,
            color: c.onBrand,
          ),
          Text(
            'SE BUSCA',
            style: MusubiType.style(
              10.5,
              weight: FontWeight.w800,
              em: 0.06,
              color: c.onBrand,
            ),
          ),
        ],
      ),
    );
  }
}

/// Boleto de `Se-busca-visitante`: icono de la categoria, el producto,
/// "Fernanda O. · hace 20 min", "PAGA HASTA" y la pastilla de la fecha.
class WantedVisitorCard extends StatelessWidget {
  const new({
    required this.request,
    required this.now,
    required this.onOffer,
    super.key,
  });

  final WantedRequest request;
  final DateTime now;
  final VoidCallback onOffer;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.brandSoft,
        borderRadius: BorderRadius.circular(24),
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
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: c.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: MusubiIcon(
                    wantedIcon(request.categorySlug),
                    size: 26,
                    strokeWidth: 1.8,
                    color: c.brandText,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 5,
                  children: [
                    Text(
                      request.title,
                      style: MusubiType.style(
                        17,
                        weight: FontWeight.w800,
                        line: 22,
                        em: -0.01,
                        color: c.textPrimary,
                      ),
                    ),
                    Row(
                      spacing: 6,
                      children: [
                        InitialsAvatar(
                          initials: initialsOf(request.requesterName),
                          size: 20,
                          fontSize: 8.5,
                          palette: _palette(request),
                        ),
                        Expanded(
                          child: Text(
                            '${request.requesterName} · '
                            '${wantedMeta(request, now, career: false)}',
                            style: MusubiType.style(
                              12.5,
                              weight: FontWeight.w600,
                              line: 17,
                              color: c.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const TicketSeparator(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: 8,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PAGA HASTA',
                      style: MusubiType.style(
                        10.5,
                        weight: FontWeight.w700,
                        em: 0.05,
                        color: c.textTertiary,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        formatPrice(request.budgetCents),
                        style: MusubiType.style(
                          28,
                          weight: FontWeight.w800,
                          line: 32,
                          em: -0.02,
                          color: c.brandStrongText,
                          tabular: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: c.background,
                  borderRadius: BorderRadius.circular(MusubiSizes.radiusChip),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 6,
                  children: [
                    MusubiIcon(
                      MusubiIcons.calendar,
                      size: 15,
                      color: c.textPrimary,
                    ),
                    Text(
                      wantedDay(request),
                      style: MusubiType.style(
                        13,
                        weight: FontWeight.w700,
                        color: c.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          MusubiButton(
            label: 'Yo tengo este producto',
            height: 48,
            fontSize: 15,
            icon: MusubiIcons.hand,
            iconSize: 19,
            onPressed: onOffer,
          ),
        ],
      ),
    );
  }
}
