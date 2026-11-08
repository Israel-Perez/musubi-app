import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_panel.dart';
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/core/widgets/musubi_text_field.dart';
import 'package:musubi_app/features/reputation/domain/reputation_models.dart';
import 'package:musubi_app/features/reputation/presentation/reputation_providers.dart';

/// Largo maximo de "Cuentanos que paso" (fila "M-13" de la API).
const reportDetailsMax = 1000;

/// `reportSheet` de la maqueta (HU-28): el motivo ("Reportar un problema",
/// con la nota de confidencialidad) y despues "Cuentanos que paso" con
/// "Enviar reporte". Desde el chat ([UserReport]) y desde Ajustes
/// ([GeneralReport]).
Future<void> showReportSheet(
  BuildContext context, {
  required ReportTarget target,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final reason = await showMusubiPanel<ReportReason>(
    context,
    builder: (context) => MusubiPanel(
      key: const Key('report-reasons'),
      title: 'Reportar un problema',
      bodyInset: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MusubiOptions<ReportReason>(
            plain: true,
            options: [
              for (final reason in ReportReason.values)
                MusubiOption(
                  value: reason,
                  label: reason.label,
                  icon: reason.icon,
                ),
            ],
            onPick: (reason) => Navigator.of(context).pop(reason),
          ),
          // `.sheet-note` dentro de `.opts`: margen de 10 a los lados.
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: PanelNote(
              'Tu reporte es confidencial. El equipo de Musubi lo revisa en '
              'menos de 24 horas.',
            ),
          ),
        ],
      ),
    ),
  );
  if (reason == null || !context.mounted) return;
  // La maqueta abre la segunda hoja 240 ms despues (`later(240, ...)`).
  await Future<void>.delayed(const Duration(milliseconds: 240));
  if (!context.mounted) return;
  final sent = await showMusubiPanel<bool>(
    context,
    builder: (_) => ReportDetailsSheet(target: target, reason: reason),
  );
  if (sent ?? false) {
    showMusubiSnack(
      messenger,
      'Recibimos tu reporte. Te escribimos en menos de 24 h.',
      icon: MusubiIcons.shieldCheck,
    );
  }
}

/// Segunda hoja de `reportSheet`: el motivo como titulo, "Cuentanos que
/// paso" (opcional) y "Enviar reporte".
class ReportDetailsSheet extends ConsumerStatefulWidget {
  const new({required this.target, required this.reason, super.key});

  final ReportTarget target;
  final ReportReason reason;

  @override
  ConsumerState<ReportDetailsSheet> createState() => _ReportDetailsSheetState();
}

class _ReportDetailsSheetState extends ConsumerState<ReportDetailsSheet> {
  final _details = TextEditingController();
  final _focus = FocusNode();
  String? _error;
  int _shake = 0;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // La maqueta enfoca el texto al abrir (`onOpen`, 350 ms).
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _details.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref
          .read(reputationRepositoryProvider)
          .report(widget.target, widget.reason, details: _details.text);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = failure.message;
        _shake++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    return MusubiPanel(
      key: const Key('report-details'),
      title: widget.reason.label,
      actions: [
        MusubiButton(
          key: const Key('report-submit'),
          label: 'Enviar reporte',
          loadingLabel: 'Enviando…',
          loading: _sending,
          height: MusubiSizes.buttonHeightSheet,
          onPressed: _send,
        ),
        MusubiButton(
          label: 'Cancelar',
          kind: MusubiButtonKind.quiet,
          height: 46,
          onPressed: _sending ? null : () => Navigator.of(context).pop(false),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: MusubiTextField(
          label: 'Cuéntanos qué pasó',
          hint: 'Incluye la fecha, el monto y lo que acordaron',
          fieldKey: const Key('report-details-field'),
          controller: _details,
          focusNode: _focus,
          enabled: !_sending,
          multiline: true,
          sheet: true,
          errorText: _error,
          shakeTrigger: _shake,
          inputFormatters: [LengthLimitingTextInputFormatter(reportDetailsMax)],
          // `.s-field small`. La maqueta remite a un "chat de soporte" que no
          // existe: el equipo responde por correo (HU-28).
          footer: Text(
            'Si tienes capturas, el equipo te las pedirá por correo.',
            // Hereda la linea de 22 del cuerpo de la hoja (`.sheet-b`).
            style: MusubiType.style(
              12.5,
              weight: FontWeight.w600,
              line: 22,
              color: c.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Abre la hoja sin esperar (desde un `onTap`).
void openReportSheet(BuildContext context, ReportTarget target) =>
    unawaited(showReportSheet(context, target: target));
