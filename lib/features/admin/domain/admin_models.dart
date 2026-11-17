import 'package:flutter/foundation.dart';
import 'package:musubi_app/core/session/session_tokens.dart';
import 'package:musubi_app/features/reputation/domain/reputation_models.dart';

// Moderacion (HU-39 y HU-40). Forma canonica: filas "M-14" de musubi-api
// `docs/endpoints.md`; aqui solo lo que usa la app.

/// Bandejas de `Administracion`.
enum AdminTab {
  open('open', 'Abiertos'),
  closed('closed', 'Revisados'),
  suspended('suspended', 'Suspendidas');

  new(this.code, this.label);

  final String code;
  final String label;
}

/// Lo que se reporta, como lo manda la API.
enum ReportedKind {
  general('general'),
  user('user'),
  product('product');

  new(this.code);

  final String code;

  static ReportedKind parse(Object? code) =>
      values.firstWhere((k) => k.code == code, orElse: () => general);
}

/// Estado de un reporte.
enum ReportStatus {
  open('open', 'Abierto'),
  dismissed('dismissed', 'Descartado'),
  upheld('upheld', 'Procedente');

  new(this.code, this.label);

  final String code;
  final String label;

  static ReportStatus parse(Object? code) =>
      values.firstWhere((s) => s.code == code, orElse: () => open);
}

/// "Descartar" o "Procedente" (`ResolveReportRequest.action`).
enum ReportAction {
  dismiss('dismiss'),
  uphold('uphold');

  new(this.code);

  final String code;
}

/// Estado de una cuenta.
enum AccountStatus {
  active('active', 'Activa'),
  suspended('suspended', 'Suspendida'),
  pending('pendingVerification', 'Sin verificar');

  new(this.code, this.label);

  final String code;
  final String label;

  static AccountStatus parse(Object? code) =>
      values.firstWhere((s) => s.code == code, orElse: () => active);
}

/// Una persona (quien reporto o quien reviso).
@immutable
class AdminPerson {
  const new({required this.id, required this.fullName});

  final String id;
  final String fullName;

  String get initials => initialsOf(fullName);
}

/// Lo reportado: una publicacion, una persona o un problema general.
@immutable
class ReportedItem {
  const new({
    required this.kind,
    this.id,
    this.name,
    this.photoUrl,
    this.status,
  });

  final ReportedKind kind;
  final String? id;

  /// Nombre de la publicacion o de la persona; `null` si ya no existe.
  final String? name;
  final String? photoUrl;

  /// Estado de la publicacion (`active`, `removed`...) o de la cuenta.
  final String? status;

  /// La publicacion ya se retiro.
  bool get removed => status == 'removed';
}

/// La persona responsable de lo reportado (RN-27).
@immutable
class ReportSubject {
  const new({
    required this.id,
    required this.fullName,
    required this.status,
    required this.upheldReports,
    required this.suspensionSuggested,
  });

  final String id;
  final String fullName;
  final AccountStatus status;
  final int upheldReports;

  /// Con 3 procedentes o mas se sugiere suspenderla.
  final bool suspensionSuggested;
}

/// La revision de un reporte.
@immutable
class ReportReview {
  const new({required this.at, this.reviewer, this.note});

  final DateTime at;
  final AdminPerson? reviewer;

  /// Nota interna; quien reporto no la ve.
  final String? note;
}

/// Un reporte de la bandeja.
@immutable
class AdminReport {
  const new({
    required this.id,
    required this.reason,
    required this.status,
    required this.createdAt,
    required this.target,
    this.details,
    this.reporter,
    this.subject,
    this.review,
  });

  final String id;
  final ReportReason reason;
  final ReportStatus status;
  final DateTime createdAt;
  final ReportedItem target;
  final String? details;
  final AdminPerson? reporter;
  final ReportSubject? subject;
  final ReportReview? review;

  bool get open => status == ReportStatus.open;

  /// Texto de "Procedente" segun lo reportado.
  String get upholdLabel => switch (target.kind) {
    ReportedKind.product => 'Retirar publicación',
    ReportedKind.user => 'Es procedente',
    ReportedKind.general => 'Marcar como atendido',
  };
}

/// Una accion de la bitacora (RNF-04).
@immutable
class AdminLogEntry {
  const new({required this.action, required this.at, this.actor, this.reason});

  final String action;
  final DateTime at;
  final AdminPerson? actor;
  final String? reason;

  /// Texto para el historial de la cuenta.
  String get label => switch (action) {
    'report_dismissed' => 'Reporte descartado',
    'report_upheld' => 'Reporte procedente',
    'product_removed' => 'Publicación retirada',
    'account_suspended' => 'Cuenta suspendida',
    'account_reactivated' => 'Cuenta reactivada',
    _ => 'Acción de moderación',
  };
}

/// Una cuenta con sus reportes procedentes y su historial (HU-40).
@immutable
class AdminAccount {
  const new({
    required this.id,
    required this.fullName,
    required this.status,
    required this.isAdmin,
    required this.memberSince,
    required this.upheldReports,
    required this.suspensionSuggested,
    this.history = const [],
  });

  final String id;
  final String fullName;
  final AccountStatus status;
  final bool isAdmin;
  final DateTime memberSince;
  final int upheldReports;
  final bool suspensionSuggested;
  final List<AdminLogEntry> history;

  String get initials => initialsOf(fullName);
}

/// Una cuenta de "Suspendidas".
@immutable
class SuspendedAccount {
  const new({
    required this.id,
    required this.fullName,
    required this.suspendedAt,
  });

  final String id;
  final String fullName;
  final DateTime suspendedAt;

  String get initials => initialsOf(fullName);
}

/// Una categoria del campus en "Categorías" (HU-41), tambien desactivada.
class AdminCategory {
  const new({
    required this.slug,
    required this.name,
    required this.active,
    required this.order,
  });

  /// Identificador estable: no cambia al renombrarla.
  final String slug;
  final String name;

  /// Sale al publicar y en los filtros.
  final bool active;
  final int order;
}

/// Largo del nombre de una categoria (como en musubi-api).
const adminCategoryNameMin = 2;
const adminCategoryNameMax = 40;
