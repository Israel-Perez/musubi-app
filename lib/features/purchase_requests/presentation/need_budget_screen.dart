import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_panel.dart';
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/core/widgets/musubi_text_field.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/listings/domain/listing_models.dart';
import 'package:musubi_app/features/listings/presentation/listings_providers.dart';
import 'package:musubi_app/features/listings/presentation/sell_layout.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/profile/presentation/profile_screen.dart';
import 'package:musubi_app/features/purchase_requests/presentation/need_edit.dart';
import 'package:musubi_app/features/purchase_requests/presentation/need_widgets.dart';
import 'package:musubi_app/features/purchase_requests/presentation/wanted_providers.dart';

/// `Necesidad-3` (HU-13): presupuesto maximo, cantidad, para cuando y "Así
/// la verá tu comunidad". "Publicar solicitud" la manda a la API.
class NeedBudgetScreen extends ConsumerStatefulWidget {
  const new({super.key, this.editing = false});

  /// "Editar solicitud" (HU-14): otro borrador, "Guardar" manda los cambios
  /// y la X vuelve a `Mis-solicitudes`.
  final bool editing;

  @override
  ConsumerState<NeedBudgetScreen> createState() => _NeedBudgetScreenState();
}

class _NeedBudgetScreenState extends ConsumerState<NeedBudgetScreen> {
  NotifierProvider<NeedDraftNotifier, NeedDraft> get _draft =>
      needDraftFor(editing: widget.editing);

  late final _budget = TextEditingController(
    text: switch (ref.read(_draft).budgetCents) {
      final cents? => '${cents ~/ 100}',
      null => '',
    },
  );
  final _budgetFocus = FocusNode();
  bool _publishing = false;
  bool _budgetError = false;

  @override
  void dispose() {
    _budget.dispose();
    _budgetFocus.dispose();
    super.dispose();
  }

  DateTime get _today => ref.read(clockProvider)().toLocal();

  /// "Elegir fecha" abre las fechas de la maqueta en una hoja de opciones.
  Future<void> _pickDate() async {
    final draft = ref.read(_draft);
    final dates = otherDates(_today);
    final picked = await showMusubiPanel<DateTime>(
      context,
      builder: (context) => MusubiPanel(
        key: const Key('need-dates'),
        title: '¿Para cuándo la necesitas?',
        bodyInset: 12,
        child: MusubiOptions<DateTime>(
          selected: draft.when == NeedWhen.custom ? draft.customDate : null,
          options: [
            for (final day in dates)
              MusubiOption(value: day, label: longDate(day)),
          ],
          onPick: (day) => Navigator.of(context).pop(day),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    ref.read(_draft.notifier).setWhen(NeedWhen.custom, date: picked);
  }

  Future<void> _publish() async {
    final draft = ref.read(_draft);
    if (draft.budgetCents == null) {
      setState(() => _budgetError = true);
      _budgetFocus.requestFocus();
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _publishing = true);
    if (widget.editing) {
      final saved = await saveNeedEdit(context, ref);
      if (!saved && mounted) setState(() => _publishing = false);
      return;
    }
    try {
      final published = await ref
          .read(wantedRepositoryProvider)
          .publish(draft.toRequest(_today));
      if (!mounted) return;
      ref.read(_draft.notifier).reset();
      ref.invalidate(myWantedProvider);
      context.go(AppRoutes.needDone, extra: published);
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() => _publishing = false);
      showMusubiSnack(
        messenger,
        failure.message,
        icon: MusubiIcons.circleAlert,
        tone: SnackTone.warn,
        bottomOffset: sellActionsHeight,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final draft = ref.watch(_draft);
    final notifier = ref.read(_draft.notifier);
    final today = _today;
    final friday = nextFriday(today);
    final category = draft.category;
    final range = category == null || category.slug == otherCategory.slug
        ? null
        : ref.watch(priceRangeProvider(category.slug)).value;
    final me = sessionProfile(ref)?.fullName ?? '';

    return SellStepLayout(
      step: 3,
      steps: 3,
      label: 'Presupuesto',
      title: '¿Cuánto y para cuándo?',
      heading: widget.editing ? needEditHeading : 'Publicar lo que necesito',
      onSave: widget.editing
          ? () => unawaited(saveNeedEdit(context, ref))
          : () => showSellSnack(
              context,
              'Borrador guardado. Lo terminas cuando quieras desde Publicar.',
            ),
      onClose: widget.editing ? () => leaveNeedEdit(context) : null,
      actions: [
        SizedBox(
          width: 112,
          child: MusubiButton(
            label: 'Atrás',
            kind: MusubiButtonKind.secondary,
            onPressed: _publishing ? null : () => context.pop(),
          ),
        ),
        Expanded(
          child: MusubiButton(
            key: const Key('need-publish'),
            label: widget.editing ? 'Guardar cambios' : 'Publicar solicitud',
            loadingLabel: widget.editing ? 'Guardando…' : 'Publicando…',
            loading: _publishing,
            icon: widget.editing ? MusubiIcons.check : MusubiIcons.megaphone,
            iconSize: 20,
            onPressed: () => unawaited(_publish()),
          ),
        ),
      ],
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              const NeedLabel('Presupuesto máximo'),
              SellFieldBox(
                focusNode: _budgetFocus,
                error: _budgetError,
                height: 64,
                radius: 16,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  spacing: 6,
                  children: [
                    Text(
                      r'$',
                      style: MusubiType.style(
                        26,
                        weight: FontWeight.w800,
                        color: c.textSecondary,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        key: const Key('need-budget'),
                        controller: _budget,
                        focusNode: _budgetFocus,
                        keyboardType: TextInputType.number,
                        cursorColor: c.brand,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        onChanged: (value) {
                          final pesos = int.tryParse(value);
                          notifier.setBudget(
                            pesos == null || pesos < 1 ? null : pesos * 100,
                          );
                          if (_budgetError) {
                            setState(() => _budgetError = false);
                          }
                        },
                        style: MusubiType.style(
                          28,
                          weight: FontWeight.w800,
                          em: -0.02,
                          color: c.textPrimary,
                        ),
                        decoration: InputDecoration.collapsed(
                          hintText: '0',
                          hintStyle: MusubiType.style(
                            28,
                            weight: FontWeight.w800,
                            em: -0.02,
                            color: c.placeholder,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      'MXN',
                      style: MusubiType.style(
                        14,
                        weight: FontWeight.w700,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_budgetError)
                const FieldMessage(
                  text: 'Indica cuánto quieres pagar como máximo.',
                )
              else if (range != null)
                _RangeHint(range: range, budgetCents: draft.budgetCents),
            ],
          ),
        ),
        NeedQuantityRow(
          quantity: draft.quantity,
          max: NeedDraft.maxQuantity,
          onStep: notifier.step,
        ),
        // `<legend>` como en `Necesidad-1`: pegado a la caja de arriba y con
        // el relleno (16) y su margen (6) debajo.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 6 + 16),
                child: NeedLabel('¿Para cuándo la necesitas?'),
              ),
              Wrap(
                spacing: 8,
                children: [
                  NeedChip(
                    key: const Key('need-when-week'),
                    label: 'Esta semana',
                    selected: draft.when == NeedWhen.thisWeek,
                    onTap: () => notifier.setWhen(NeedWhen.thisWeek),
                  ),
                  NeedChip(
                    key: const Key('need-when-friday'),
                    label: _capitalize(shortDate(friday)),
                    selected: draft.when == NeedWhen.friday,
                    onTap: () => notifier.setWhen(NeedWhen.friday),
                  ),
                  NeedChip(
                    key: const Key('need-when-date'),
                    label:
                        draft.when == NeedWhen.custom &&
                            draft.customDate != null
                        ? _capitalize(shortDate(draft.customDate!))
                        : 'Elegir fecha',
                    icon: MusubiIcons.calendar,
                    selected: draft.when == NeedWhen.custom,
                    onTap: () => unawaited(_pickDate()),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              Row(
                spacing: 6,
                children: [
                  MusubiIcon(MusubiIcons.eye, size: 15, color: c.textSecondary),
                  Text(
                    'Así la verá tu comunidad',
                    style: MusubiType.style(
                      13,
                      weight: FontWeight.w700,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
              WantedPreviewCard(
                title: draft.title.trim(),
                budgetCents: draft.budgetCents,
                meta: [
                  ?category?.name,
                  if (me.isNotEmpty) shortPersonName(me),
                ].join(' · '),
                when: needWhenLine(draft.neededBy(today), draft.quantity),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Buen presupuesto: en Musubi se venden entre $380 y $580." (verde) o, por
/// debajo del rango, solo el rango (gris).
class _RangeHint extends StatelessWidget {
  const new({required this.range, required this.budgetCents});

  final PriceRange range;
  final int? budgetCents;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final low = range.lowCents;
    final high = range.highCents;
    final good = budgetCents != null && budgetCents! >= low;
    final text = good
        ? 'Buen presupuesto: en Musubi se venden entre ${formatPrice(low)} y '
              '${formatPrice(high)}.'
        : 'En Musubi se venden entre ${formatPrice(low)} y '
              '${formatPrice(high)}.';
    final color = good ? c.successText : c.textSecondary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: MusubiIcon(
            good ? MusubiIcons.check : MusubiIcons.info,
            size: 16,
            strokeWidth: good ? 2.4 : 2,
            color: color,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: MusubiType.style(
              13,
              weight: FontWeight.w600,
              line: 18,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

String _capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

/// "Ana Sofía Ramírez" → "Ana R." (como la API).
String shortPersonName(String fullName) {
  final parts = fullName.trim().split(RegExp(r'\s+'));
  if (parts.length == 1) return parts.first;
  return '${parts.first} ${parts.last[0].toUpperCase()}.';
}
