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
import 'package:musubi_app/core/widgets/top_bar.dart';
import 'package:musubi_app/features/admin/domain/admin_models.dart';
import 'package:musubi_app/features/admin/presentation/admin_providers.dart';
import 'package:musubi_app/features/admin/presentation/admin_report_sheet.dart';
import 'package:musubi_app/features/admin/presentation/admin_widgets.dart';

/// "Administración" (HU-39 y HU-40), desde `Ajustes` y solo para el rol
/// `admin`. La maqueta no la tiene: se arma con las pestanas de
/// `Notificaciones` y las tarjetas de `Ajustes`.
class AdminScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  AdminTab _tab = AdminTab.open;

  static String _messageOf(Object error) => error is ApiFailure
      ? error.message
      : 'No pudimos cargar la administración. Intenta de nuevo.';

  void _retry() => refreshModeration(ref);

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return Scaffold(
      backgroundColor: c.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MusubiTopBar(
            onBack: () => context.canPop()
                ? context.pop()
                : context.go(AppRoutes.settings),
            title: 'Administración',
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Row(
              spacing: 8,
              children: [
                for (final tab in AdminTab.values)
                  AdminTabChip(
                    key: Key('admin-tab-${tab.code}'),
                    label: tab.label,
                    selected: tab == _tab,
                    onTap: () => setState(() => _tab = tab),
                  ),
              ],
            ),
          ),
          Expanded(
            child: switch (_tab) {
              AdminTab.suspended => _Suspended(
                accounts: ref.watch(suspendedAccountsProvider),
                messageOf: _messageOf,
                onRetry: _retry,
              ),
              _ => _Reports(
                open: _tab == AdminTab.open,
                reports: ref.watch(adminReportsProvider(_tab == AdminTab.open)),
                messageOf: _messageOf,
                onRetry: _retry,
              ),
            },
          ),
        ],
      ),
    );
  }
}

class _Reports extends StatelessWidget {
  const new({
    required this.open,
    required this.reports,
    required this.messageOf,
    required this.onRetry,
  });

  final bool open;
  final AsyncValue<List<AdminReport>> reports;
  final String Function(Object) messageOf;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => switch (reports) {
    AsyncData(value: []) => EmptyView(
      icon: MusubiIcons.shieldCheck,
      title: open ? 'Sin reportes abiertos' : 'Sin reportes revisados',
      message: open
          ? 'Cuando alguien reporte algo en tu campus, aparece aquí.'
          : 'Aquí quedan los reportes que ya revisaste.',
    ),
    AsyncData(:final value) => ListView.separated(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.paddingOf(context).bottom + 24,
      ),
      itemCount: value.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _ReportCard(report: value[i]),
    ),
    AsyncError(:final error) => ErrorView(
      message: messageOf(error),
      onRetry: onRetry,
    ),
    _ => const LoadingView(message: 'Cargando reportes…'),
  };
}

class _ReportCard extends StatelessWidget {
  const new({required this.report});

  final AdminReport report;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return AdminCard(
      key: Key('admin-report-${report.id}'),
      onTap: () => unawaited(showAdminReportSheet(context, report)),
      semanticLabel: report.reason.label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 6,
        children: [
          Row(
            spacing: 8,
            children: [
              MusubiIcon(report.reason.icon, size: 18, color: c.brandText),
              Expanded(
                child: Text(
                  report.reason.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: MusubiType.style(
                    15,
                    weight: FontWeight.w800,
                    line: 20,
                    color: c.textPrimary,
                  ),
                ),
              ),
              if (!report.open)
                StatusPill(
                  report.status.label,
                  tone: report.status == ReportStatus.upheld
                      ? PillTone.danger
                      : PillTone.neutral,
                ),
            ],
          ),
          AdminLine(
            report.target.kind == ReportedKind.product
                ? MusubiIcons.package
                : MusubiIcons.user,
            reportedLine(report.target),
          ),
          if (report.details case final details?)
            Text(
              details,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: MusubiType.bodySmall.copyWith(color: c.textSecondary),
            ),
          Text(
            adminDate(report.createdAt),
            style: MusubiType.style(
              12,
              weight: FontWeight.w600,
              color: c.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Suspended extends StatelessWidget {
  const new({
    required this.accounts,
    required this.messageOf,
    required this.onRetry,
  });

  final AsyncValue<List<SuspendedAccount>> accounts;
  final String Function(Object) messageOf;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => switch (accounts) {
    AsyncData(value: []) => const EmptyView(
      icon: MusubiIcons.users,
      title: 'Sin cuentas suspendidas',
      message: 'Las cuentas que suspendas aparecen aquí para reactivarlas.',
    ),
    AsyncData(:final value) => ListView.separated(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.paddingOf(context).bottom + 24,
      ),
      itemCount: value.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final account = value[i];
        return AdminCard(
          key: Key('admin-suspended-${account.id}'),
          onTap: () =>
              unawaited(context.push(AppRoutes.adminAccount(account.id))),
          semanticLabel: account.fullName,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    AdminLine(
                      MusubiIcons.userRound,
                      account.fullName,
                      strong: true,
                    ),
                    AdminLine(
                      MusubiIcons.ban,
                      'Suspendida el ${adminDate(account.suspendedAt)}',
                    ),
                  ],
                ),
              ),
              MusubiIcon(
                MusubiIcons.chevronRight,
                color: context.musubi.chevron,
              ),
            ],
          ),
        );
      },
    ),
    AsyncError(:final error) => ErrorView(
      message: messageOf(error),
      onRetry: onRetry,
    ),
    _ => const LoadingView(message: 'Cargando cuentas…'),
  };
}
