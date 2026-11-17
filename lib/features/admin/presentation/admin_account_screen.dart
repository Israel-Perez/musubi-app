import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/avatars.dart';
import 'package:musubi_app/core/widgets/feedback_views.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_dialog.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_panel.dart';
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/core/widgets/musubi_text_field.dart';
import 'package:musubi_app/core/widgets/top_bar.dart';
import 'package:musubi_app/features/admin/domain/admin_models.dart';
import 'package:musubi_app/features/admin/presentation/admin_providers.dart';
import 'package:musubi_app/features/admin/presentation/admin_report_sheet.dart';
import 'package:musubi_app/features/admin/presentation/admin_widgets.dart';

/// Una cuenta en "Administración" (HU-40): sus reportes procedentes (RN-27),
/// su historial de moderación (RNF-04) y "Suspender cuenta" o "Reactivar
/// cuenta".
class AdminAccountScreen extends ConsumerStatefulWidget {
  const new({required this.userId, super.key});

  final String userId;

  @override
  ConsumerState<AdminAccountScreen> createState() => _AdminAccountScreenState();
}

class _AdminAccountScreenState extends ConsumerState<AdminAccountScreen> {
  bool _saving = false;

  Future<void> _suspend(AdminAccount account) async {
    final messenger = ScaffoldMessenger.of(context);
    final done = await showMusubiPanel<bool>(
      context,
      builder: (_) => SuspendAccountSheet(account: account),
    );
    if (!(done ?? false)) return;
    refreshModeration(ref, userId: account.id);
    showMusubiSnack(messenger, 'Suspendimos la cuenta', icon: MusubiIcons.ban);
  }

  Future<void> _reactivate(AdminAccount account) async {
    final yes = await showMusubiDialog(
      context,
      icon: MusubiIcons.refreshCw,
      title: '¿Reactivar la cuenta?',
      message:
          '${account.fullName} podrá volver a iniciar sesión. Sus '
          'publicaciones siguen pausadas hasta que las reactive.',
      confirmLabel: 'Reactivar',
      confirmKey: const Key('admin-reactivate-confirm'),
    );
    if (!yes || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      await ref.read(adminRepositoryProvider).reactivate(account.id);
    } on ApiFailure catch (failure) {
      if (mounted) setState(() => _saving = false);
      showMusubiSnack(messenger, failure.message, tone: SnackTone.warn);
      return;
    }
    refreshModeration(ref, userId: account.id);
    if (mounted) setState(() => _saving = false);
    showMusubiSnack(
      messenger,
      'Reactivamos la cuenta',
      icon: MusubiIcons.circleCheck,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final account = ref.watch(adminAccountProvider(widget.userId));
    return Scaffold(
      backgroundColor: c.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MusubiTopBar(
            onBack: () => context.canPop()
                ? context.pop()
                : context.go(AppRoutes.settingsAdmin),
            title: 'Cuenta',
          ),
          Expanded(
            child: switch (account) {
              AsyncData(:final value) => _Body(
                account: value,
                saving: _saving,
                onSuspend: () => unawaited(_suspend(value)),
                onReactivate: () => unawaited(_reactivate(value)),
              ),
              AsyncError(:final error) => ErrorView(
                message: error is ApiFailure
                    ? error.message
                    : 'No pudimos cargar la cuenta. Intenta de nuevo.',
                onRetry: () =>
                    ref.invalidate(adminAccountProvider(widget.userId)),
              ),
              _ => const LoadingView(message: 'Cargando la cuenta…'),
            },
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const new({
    required this.account,
    required this.saving,
    required this.onSuspend,
    required this.onReactivate,
  });

  final AdminAccount account;
  final bool saving;
  final VoidCallback onSuspend;
  final VoidCallback onReactivate;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final suspended = account.status == AccountStatus.suspended;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.paddingOf(context).bottom + 24,
      ),
      children: [
        Row(
          spacing: 14,
          children: [
            InitialsAvatar(initials: account.initials, size: 56),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 6,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      account.fullName,
                      style: MusubiType.style(
                        20,
                        weight: FontWeight.w800,
                        line: 25,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                  Row(
                    spacing: 6,
                    children: [
                      StatusPill(
                        account.status.label,
                        tone: suspended ? PillTone.danger : PillTone.success,
                      ),
                      if (account.isAdmin) const StatusPill('Administración'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        AdminCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              AdminLine(MusubiIcons.shield, switch (account.upheldReports) {
                0 => 'Sin reportes procedentes',
                1 => '1 reporte procedente',
                final n => '$n reportes procedentes',
              }, strong: true),
              AdminLine(
                MusubiIcons.calendar,
                'En Musubi desde el ${adminDate(account.memberSince)}',
              ),
            ],
          ),
        ),
        if (account.suspensionSuggested) ...[
          const SizedBox(height: 12),
          const InlineMessage(
            key: Key('admin-suggestion'),
            kind: InlineMessageKind.warning,
            title: 'Se sugiere suspenderla',
            message:
                'Tiene 3 reportes procedentes o más (RN-27). La decisión es '
                'tuya.',
          ),
        ],
        const SizedBox(height: 18),
        if (account.isAdmin)
          const PanelNote(
            'Es una cuenta de administración: no se puede suspender.',
          )
        else if (suspended)
          MusubiButton(
            key: const Key('admin-reactivate'),
            label: 'Reactivar cuenta',
            loadingLabel: 'Reactivando…',
            kind: MusubiButtonKind.secondary,
            loading: saving,
            onPressed: onReactivate,
          )
        else if (account.status == AccountStatus.active)
          MusubiButton(
            key: const Key('admin-suspend'),
            label: 'Suspender cuenta',
            onPressed: onSuspend,
          ),
        const SizedBox(height: 24),
        Text(
          'HISTORIAL',
          style: MusubiType.eyebrow.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: 10),
        if (account.history.isEmpty)
          Text(
            'Todavía no hay acciones de moderación.',
            style: MusubiType.bodySmall.copyWith(color: c.textSecondary),
          )
        else
          for (final entry in account.history)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AdminCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 4,
                  children: [
                    AdminLine(MusubiIcons.clock, entry.label, strong: true),
                    Text(
                      [
                        adminDate(entry.at),
                        if (entry.actor case final actor?) actor.fullName,
                      ].join(' · '),
                      style: MusubiType.style(
                        12.5,
                        weight: FontWeight.w600,
                        color: c.textSecondary,
                      ),
                    ),
                    if (entry.reason case final reason?)
                      Text(
                        reason,
                        style: MusubiType.bodySmall.copyWith(
                          color: c.textPrimary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

/// "Suspender cuenta" con su motivo (obligatorio, hasta 500 caracteres).
class SuspendAccountSheet extends ConsumerStatefulWidget {
  const new({required this.account, super.key});

  final AdminAccount account;

  @override
  ConsumerState<SuspendAccountSheet> createState() =>
      _SuspendAccountSheetState();
}

class _SuspendAccountSheetState extends ConsumerState<SuspendAccountSheet> {
  final _reason = TextEditingController();
  String? _error;
  int _shake = 0;
  bool _sending = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_reason.text.trim().isEmpty) {
      setState(() {
        _error = 'Escribe el motivo de la suspensión.';
        _shake++;
      });
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref
          .read(adminRepositoryProvider)
          .suspend(widget.account.id, _reason.text);
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
  Widget build(BuildContext context) => MusubiPanel(
    key: const Key('admin-suspend-sheet'),
    title: 'Suspender a ${widget.account.fullName}',
    actions: [
      MusubiButton(
        key: const Key('admin-suspend-submit'),
        label: 'Suspender cuenta',
        loadingLabel: 'Suspendiendo…',
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
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        const SizedBox(height: 4),
        MusubiTextField(
          label: 'Motivo',
          hint: 'Por ejemplo: pidió pagos fuera de Musubi',
          fieldKey: const Key('admin-suspend-reason'),
          controller: _reason,
          enabled: !_sending,
          multiline: true,
          sheet: true,
          errorText: _error,
          shakeTrigger: _shake,
          inputFormatters: [LengthLimitingTextInputFormatter(adminNoteMax)],
        ),
        const PanelNote(
          'No podrá iniciar sesión y sus publicaciones se pausan. El motivo '
          'queda en el historial.',
        ),
      ],
    ),
  );
}
