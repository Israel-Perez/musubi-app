import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/feedback_views.dart';
import 'package:musubi_app/core/widgets/top_bar.dart';
import 'package:musubi_app/features/admin/domain/admin_models.dart';
import 'package:musubi_app/features/admin/presentation/admin_providers.dart';
import 'package:musubi_app/features/admin/presentation/admin_widgets.dart';

/// "Indicadores de uso" (HU-42), desde `Ajustes` → "Administración" y solo
/// para el rol `admin`. La maqueta no la tiene: se arma con las pestanas y
/// las tarjetas de "Administración". Son conteos del campus, sin personas.
class AdminIndicatorsScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<AdminIndicatorsScreen> createState() =>
      _AdminIndicatorsScreenState();
}

class _AdminIndicatorsScreenState extends ConsumerState<AdminIndicatorsScreen> {
  IndicatorPeriod _period = IndicatorPeriod.week;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final indicators = ref.watch(adminIndicatorsProvider(_period));
    return Scaffold(
      backgroundColor: c.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MusubiTopBar(
            onBack: () => context.canPop()
                ? context.pop()
                : context.go(AppRoutes.settings),
            title: 'Indicadores de uso',
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Row(
              spacing: 8,
              children: [
                for (final period in IndicatorPeriod.values)
                  AdminTabChip(
                    key: Key('indicators-${period.code}'),
                    label: period.label,
                    selected: period == _period,
                    onTap: () => setState(() => _period = period),
                  ),
              ],
            ),
          ),
          Expanded(
            child: switch (indicators) {
              AsyncData(:final value) => _Areas(indicators: value),
              AsyncError(:final error) => ErrorView(
                message: error is ApiFailure
                    ? error.message
                    : 'No pudimos cargar los indicadores. Intenta de nuevo.',
                onRetry: () => ref.invalidate(adminIndicatorsProvider(_period)),
              ),
              _ => const LoadingView(message: 'Cargando indicadores…'),
            },
          ),
        ],
      ),
    );
  }
}

class _Areas extends StatelessWidget {
  const new({required this.indicators});

  final UsageIndicators indicators;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return ListView(
      key: const Key('indicators-list'),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.paddingOf(context).bottom + 24,
      ),
      children: [
        Text(
          'Conteos de tu campus, sin datos de nadie. Las ventas que se '
          'cierran fuera de la app no se cuentan.',
          style: MusubiType.style(13, line: 18, color: c.textSecondary),
        ),
        for (final area in indicators.areas) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
            child: Text(
              area.title.toUpperCase(),
              style: MusubiType.style(
                12,
                weight: FontWeight.w800,
                em: 0.06,
                color: c.textSecondary,
              ),
            ),
          ),
          Column(
            spacing: 10,
            children: [
              for (final item in area.items) _IndicatorCard(indicator: item),
            ],
          ),
        ],
      ],
    );
  }
}

class _IndicatorCard extends StatelessWidget {
  const new({required this.indicator});

  final UsageIndicator indicator;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final shown = indicator.value == null ? 'sin datos' : indicator.display;
    return AdminCard(
      key: Key('indicator-${indicator.key}'),
      semanticLabel: '${indicator.label}: $shown. ${indicator.detail}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            spacing: 12,
            children: [
              Expanded(
                child: Text(
                  indicator.label,
                  style: MusubiType.style(
                    14.5,
                    weight: FontWeight.w700,
                    color: c.textPrimary,
                  ),
                ),
              ),
              Text(
                indicator.display,
                style: MusubiType.style(
                  22,
                  weight: FontWeight.w800,
                  color: indicator.value == null
                      ? c.textSecondary
                      : c.textPrimary,
                ),
              ),
            ],
          ),
          Text(
            indicator.value == null && indicator.unit == IndicatorUnit.percent
                ? 'Aún no hay datos para calcularlo. ${indicator.detail}'
                : indicator.detail,
            style: MusubiType.style(13, line: 18, color: c.textSecondary),
          ),
          if (indicator.breakdown.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final part in indicator.breakdown)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: c.background,
                        borderRadius: BorderRadius.circular(
                          MusubiSizes.radiusChip,
                        ),
                      ),
                      child: Text(
                        '${part.label} · ${part.value}',
                        style: MusubiType.style(
                          12.5,
                          weight: FontWeight.w600,
                          color: c.textPrimary,
                        ),
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
