import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/feedback_views.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_panel.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/core/widgets/skeleton.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/purchase_requests/domain/wanted_models.dart';
import 'package:musubi_app/features/purchase_requests/presentation/need_widgets.dart';
import 'package:musubi_app/features/purchase_requests/presentation/received_offers.dart';
import 'package:musubi_app/features/purchase_requests/presentation/wanted_providers.dart';

/// `Mis-solicitudes` (HU-13): "Activas" y "Cerradas", la solicitud elegida
/// ("Cambiar" elige otra) y sus ofertas ("Compara las ofertas", HU-17).
/// NOTE (HU-14): "Cambiar" tambien edita, cierra o cancela.
class MyWantedScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<MyWantedScreen> createState() => _MyWantedScreenState();
}

class _MyWantedScreenState extends ConsumerState<MyWantedScreen> {
  bool _closed = false;
  String? _selectedId;

  Future<void> _change(List<WantedRequest> options) async {
    final picked = await showMusubiPanel<String>(
      context,
      builder: (context) => MusubiPanel(
        key: const Key('my-wanted-change'),
        title: 'Elige una solicitud',
        bodyInset: 12,
        child: MusubiOptions<String>(
          selected: _selectedId ?? options.first.id,
          options: [
            for (final r in options)
              MusubiOption(
                value: r.id,
                label: r.title,
                sub: [
                  'Hasta ${formatPrice(r.budgetCents)}',
                  if (r.neededBy case final day?) shortDate(day),
                  if (r.quantity > 1) piecesText(r.quantity),
                ].join(' · '),
              ),
          ],
          onPick: (id) => Navigator.of(context).pop(id),
        ),
      ),
    );
    if (picked != null && mounted) setState(() => _selectedId = picked);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final mine = ref.watch(myWantedProvider);
    final all = mine.value ?? const <WantedRequest>[];
    final active = [...all.where((r) => r.isActive)];
    final closed = [...all.where((r) => !r.isActive)];
    final tab = _closed ? closed : active;
    final selected = tab.isEmpty
        ? null
        : tab.firstWhere((r) => r.id == _selectedId, orElse: () => tab.first);

    return Scaffold(
      backgroundColor: c.surface,
      body: RefreshIndicator(
        color: c.brand,
        onRefresh: () => ref.refresh(myWantedProvider.future),
        child: ListView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.paddingOf(context).bottom + 24,
          ),
          children: [
            ColoredBox(
              color: c.background,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(
                        onNew: () => unawaited(context.push(AppRoutes.need)),
                      ),
                      _Tabs(
                        closed: _closed,
                        active: active.length,
                        others: closed.length,
                        onSelect: (closedTab) => setState(() {
                          _closed = closedTab;
                          _selectedId = null;
                        }),
                      ),
                      if (mine.isLoading && mine.value == null)
                        const Padding(
                          padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                          child: SkeletonShimmer(
                            child: SkeletonBox(
                              width: 350,
                              height: 104,
                              radius: 18,
                            ),
                          ),
                        )
                      else if (mine.hasError && mine.value == null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                          child: InlineMessage(
                            message: switch (mine.error) {
                              final ApiFailure f => f.message,
                              _ => 'No pudimos cargar tus solicitudes.',
                            },
                          ),
                        )
                      else if (selected == null)
                        _Empty(closed: _closed)
                      else
                        _SelectedCard(
                          request: selected,
                          onChange: tab.length > 1
                              ? () => unawaited(_change(tab))
                              : null,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (selected != null)
              ReceivedOffersSection(
                key: ValueKey('offers-${selected.id}'),
                request: selected,
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const new({required this.onNew});

  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Pressable(
            // Desde "Ver mi solicitud" no hay nada atras: vuelve a Perfil.
            onTap: () => context.canPop()
                ? context.pop()
                : context.go(AppRoutes.profile),
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
          Semantics(
            header: true,
            child: Text(
              'Mis solicitudes',
              style: MusubiType.style(
                17,
                weight: FontWeight.w800,
                color: c.textPrimary,
              ),
            ),
          ),
          Pressable(
            key: const Key('my-wanted-new'),
            onTap: onNew,
            semanticLabel: 'Nueva solicitud',
            builder: (context, _) => SizedBox.square(
              dimension: MusubiSizes.minTouch,
              child: Center(
                child: MusubiIcon(
                  MusubiIcons.plus,
                  strokeWidth: 2.2,
                  color: c.brand,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Activas (2)" / "Cerradas (4)": segmentos de 44 sobre gris.
class _Tabs extends StatelessWidget {
  const new({
    required this.closed,
    required this.active,
    required this.others,
    required this.onSelect,
  });

  final bool closed;
  final int active;
  final int others;
  final ValueChanged<bool> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    Widget tab(String label, {required bool on, required bool value}) =>
        Expanded(
          child: Semantics(
            selected: on,
            child: Pressable(
              key: Key('my-wanted-tab-${value ? 'closed' : 'active'}'),
              onTap: () => onSelect(value),
              semanticLabel: label,
              builder: (context, _) => Container(
                decoration: BoxDecoration(
                  color: on ? c.background : null,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: on
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
                  style: MusubiType.style(
                    14,
                    weight: on ? FontWeight.w800 : FontWeight.w600,
                    color: on ? c.textPrimary : c.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        );
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        spacing: 3,
        children: [
          tab('Activas ($active)', on: !closed, value: false),
          tab('Cerradas ($others)', on: closed, value: true),
        ],
      ),
    );
  }
}

/// La solicitud elegida: "SE BUSCA", "Cambiar", nombre, "Hasta $600", fecha y
/// ofertas.
class _SelectedCard extends StatelessWidget {
  const new({required this.request, required this.onChange});

  final WantedRequest request;
  final VoidCallback? onChange;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final small = MusubiType.style(
      12.5,
      weight: FontWeight.w700,
      color: c.textPrimary,
    );
    return Container(
      key: const Key('my-wanted-card'),
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.brandSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            spacing: 8,
            children: [
              const SeBuscaBadge(small: true),
              if (onChange != null)
                Pressable(
                  key: const Key('my-wanted-change-button'),
                  onTap: onChange,
                  semanticLabel: 'Cambiar de solicitud',
                  builder: (context, _) => SizedBox(
                    height: 32,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 4,
                      children: [
                        Text(
                          'Cambiar',
                          style: MusubiType.style(
                            12.5,
                            weight: FontWeight.w700,
                            color: c.brandStrongText,
                          ),
                        ),
                        MusubiIcon(
                          MusubiIcons.chevronDown,
                          size: 14,
                          strokeWidth: 2.4,
                          color: c.brandStrongText,
                        ),
                      ],
                    ),
                  ),
                )
              else if (!request.isActive)
                Text(
                  switch (request.status) {
                    WantedStatus.closed => 'Cerrada',
                    WantedStatus.cancelled => 'Cancelada',
                    _ => 'Vencida',
                  },
                  style: MusubiType.style(
                    12.5,
                    weight: FontWeight.w700,
                    color: c.textSecondary,
                  ),
                ),
            ],
          ),
          Text(
            request.title,
            style: MusubiType.style(
              15.5,
              weight: FontWeight.w800,
              line: 20,
              color: c.textPrimary,
            ),
          ),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Hasta '),
                    TextSpan(
                      text: formatPrice(request.budgetCents),
                      style: TextStyle(
                        color: c.brandStrongText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                style: small,
              ),
              if (request.neededBy case final day?)
                _IconText(MusubiIcons.calendar, shortDate(day), small),
              // Una pieza es lo normal; más de una se dice.
              if (request.quantity > 1)
                _IconText(
                  MusubiIcons.shoppingBag,
                  piecesText(request.quantity),
                  small,
                ),
              _IconText(
                MusubiIcons.hand,
                request.offersCount == 1
                    ? '1 oferta'
                    : '${request.offersCount} ofertas',
                small,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconText extends StatelessWidget {
  const new(this.icon, this.text, this.style);

  final MusubiIconData icon;
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: 4,
    children: [
      MusubiIcon(icon, size: 13, color: style.color),
      Text(text, style: style),
    ],
  );
}

/// "Compara las ofertas": hoy, sin ofertas (llegan con HU-16).
/// Sin solicitudes en la pestaña.
class _Empty extends StatelessWidget {
  const new({required this.closed});

  final bool closed;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
      child: Column(
        spacing: 12,
        children: [
          Text(
            closed
                ? 'Aquí verás las solicitudes que cierres o que venzan.'
                : 'No tienes solicitudes activas. Publica lo que necesitas y '
                      'te avisamos cuando alguien lo tenga.',
            textAlign: TextAlign.center,
            style: MusubiType.style(
              14.5,
              weight: FontWeight.w600,
              line: 20,
              color: c.textSecondary,
            ),
          ),
          if (!closed)
            MusubiButton(
              key: const Key('my-wanted-empty-new'),
              label: 'Publicar lo que necesito',
              icon: MusubiIcons.megaphone,
              height: MusubiSizes.buttonHeightSheet,
              onPressed: () => unawaited(context.push(AppRoutes.need)),
            ),
        ],
      ),
    );
  }
}
