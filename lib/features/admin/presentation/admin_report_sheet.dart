import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/feedback_views.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_dialog.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_panel.dart';
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/core/widgets/musubi_text_field.dart';
import 'package:musubi_app/features/admin/domain/admin_models.dart';
import 'package:musubi_app/features/admin/presentation/admin_providers.dart';
import 'package:musubi_app/features/admin/presentation/admin_widgets.dart';

/// Largo maximo de la nota interna (fila "M-14" de la API).
const adminNoteMax = 500;

/// Que se reporto, en una linea.
String reportedLine(ReportedItem target) => switch (target.kind) {
  ReportedKind.product => 'Publicación · ${target.name ?? 'ya no existe'}',
  ReportedKind.user => 'Persona · ${target.name ?? 'cuenta eliminada'}',
  ReportedKind.general => 'Problema general',
};

/// Abre el reporte (HU-39): lo reportado, el detalle, la persona responsable
/// y, si sigue abierto, "Descartar" y "Procedente" con una nota interna.
Future<void> showAdminReportSheet(BuildContext context, AdminReport report) =>
    showMusubiPanel<void>(
      context,
      builder: (_) => AdminReportSheet(report: report),
    );

class AdminReportSheet extends ConsumerStatefulWidget {
  const new({required this.report, super.key});

  final AdminReport report;

  @override
  ConsumerState<AdminReportSheet> createState() => _AdminReportSheetState();
}

class _AdminReportSheetState extends ConsumerState<AdminReportSheet> {
  final _note = TextEditingController();
  ReportAction? _sending;
  String? _error;
  int _shake = 0;

  AdminReport get _report => widget.report;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _resolve(ReportAction action) async {
    // Retirar una publicacion no se deshace desde la app: se confirma.
    if (action == ReportAction.uphold &&
        _report.target.kind == ReportedKind.product) {
      final yes = await showMusubiDialog(
        context,
        icon: MusubiIcons.trash,
        title: '¿Retirar la publicación?',
        message:
            'Deja de verse en Musubi y le avisamos a quien la vende. El '
            'reporte queda como procedente.',
        confirmLabel: 'Retirar',
        danger: true,
        confirmKey: const Key('admin-remove-confirm'),
      );
      if (!yes || !mounted) return;
    }
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _sending = action;
      _error = null;
    });
    try {
      await ref
          .read(adminRepositoryProvider)
          .resolve(_report.id, action, note: _note.text);
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _sending = null;
        _error = failure.message;
        _shake++;
      });
      return;
    }
    refreshModeration(ref, userId: _report.subject?.id);
    if (!mounted) return;
    Navigator.of(context).pop();
    showMusubiSnack(messenger, switch (action) {
      ReportAction.dismiss => 'Descartamos el reporte',
      ReportAction.uphold when _report.target.kind == ReportedKind.product =>
        'Retiramos la publicación',
      ReportAction.uphold => 'Marcamos el reporte como procedente',
    }, icon: MusubiIcons.shieldCheck);
  }

  static String _reporterName(AdminReport report) =>
      report.reporter?.fullName ?? 'una cuenta eliminada';

  void _openAccount(String userId) {
    Navigator.of(context).pop();
    unawaited(context.push(AppRoutes.adminAccount(userId)));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final report = _report;
    final subject = report.subject;
    final review = report.review;
    final busy = _sending != null;
    return MusubiPanel(
      key: const Key('admin-report'),
      title: report.reason.label,
      tall: true,
      actions: report.open
          ? [
              MusubiButton(
                key: const Key('admin-uphold'),
                label: report.upholdLabel,
                loadingLabel: 'Guardando…',
                loading: _sending == ReportAction.uphold,
                height: MusubiSizes.buttonHeightSheet,
                onPressed: busy
                    ? null
                    : () => unawaited(_resolve(ReportAction.uphold)),
              ),
              MusubiButton(
                key: const Key('admin-dismiss'),
                label: 'Descartar',
                loadingLabel: 'Guardando…',
                kind: MusubiButtonKind.secondary,
                loading: _sending == ReportAction.dismiss,
                height: 46,
                onPressed: busy
                    ? null
                    : () => unawaited(_resolve(ReportAction.dismiss)),
              ),
            ]
          : const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          const SizedBox(height: 4),
          AdminCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AdminLine(
                        report.target.kind == ReportedKind.product
                            ? MusubiIcons.package
                            : MusubiIcons.user,
                        reportedLine(report.target),
                        strong: true,
                      ),
                    ),
                    if (report.target.removed)
                      const StatusPill('Retirada', tone: PillTone.danger),
                  ],
                ),
                AdminLine(
                  MusubiIcons.flag,
                  'Reportó ${_reporterName(report)} · '
                  '${adminDate(report.createdAt)}',
                ),
                if (report.details case final details?)
                  Text(
                    details,
                    key: const Key('admin-report-details'),
                    style: MusubiType.body.copyWith(color: c.textPrimary),
                  ),
              ],
            ),
          ),
          if (subject != null)
            AdminCard(
              key: const Key('admin-report-subject'),
              onTap: () => _openAccount(subject.id),
              semanticLabel: 'Ver la cuenta de ${subject.fullName}',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 6,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AdminLine(
                          MusubiIcons.userRound,
                          subject.fullName,
                          strong: true,
                        ),
                      ),
                      if (subject.status == AccountStatus.suspended)
                        const StatusPill('Suspendida', tone: PillTone.danger),
                    ],
                  ),
                  AdminLine(MusubiIcons.shield, switch (subject.upheldReports) {
                    0 => 'Sin reportes procedentes',
                    1 => '1 reporte procedente',
                    final n => '$n reportes procedentes',
                  }),
                  if (subject.suspensionSuggested)
                    const InlineMessage(
                      kind: InlineMessageKind.warning,
                      message:
                          'Tiene 3 reportes procedentes o más: considera '
                          'suspender su cuenta.',
                    ),
                  Text(
                    'Ver cuenta',
                    style: MusubiType.style(
                      13.5,
                      weight: FontWeight.w800,
                      color: c.brandText,
                    ),
                  ),
                ],
              ),
            ),
          if (review != null)
            AdminCard(
              key: const Key('admin-report-review'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 6,
                children: [
                  AdminLine(
                    MusubiIcons.circleCheck,
                    '${report.status.label} · ${adminDate(review.at)}',
                    strong: true,
                  ),
                  if (review.reviewer case final reviewer?)
                    AdminLine(MusubiIcons.user, 'Revisó ${reviewer.fullName}'),
                  if (review.note case final note?)
                    Text(
                      note,
                      style: MusubiType.body.copyWith(color: c.textPrimary),
                    ),
                ],
              ),
            ),
          if (report.open)
            MusubiTextField(
              label: 'Nota interna (opcional)',
              hint: 'Qué revisaste y por qué',
              fieldKey: const Key('admin-note'),
              controller: _note,
              enabled: !busy,
              multiline: true,
              sheet: true,
              errorText: _error,
              shakeTrigger: _shake,
              inputFormatters: [LengthLimitingTextInputFormatter(adminNoteMax)],
            ),
          if (report.open)
            const PanelNote(
              'Quien reportó recibe "Revisamos tu reporte"; la nota no la ve.',
            ),
        ],
      ),
    );
  }
}
