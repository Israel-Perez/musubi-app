import 'dart:convert';

import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/session/session_tokens.dart';
import 'package:musubi_app/features/admin/domain/admin_models.dart';
import 'package:musubi_app/features/admin/domain/admin_repository.dart';
import 'package:musubi_app/features/reputation/domain/reputation_models.dart';

/// Un access token con forma de JWT, `sub` y `role` (la firma no importa: la
/// app solo lo lee; la API es la que decide).
String jwtWithRoles(String sub, List<String> roles) {
  String part(Map<String, Object> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  return '${part({'alg': 'HS256'})}.${part({'sub': sub, 'role': roles})}.firma';
}

/// Sesion de una persona administradora (HU-39).
SessionTokens adminTokens() => SessionTokens(
  accessToken: jwtWithRoles('admin-1', ['student', 'admin']),
  accessExpiresAt: DateTime.utc(2026, 11, 16, 12, 15),
  refreshToken: 'refresh-admin',
  profile: const SessionProfile(
    fullName: 'Equipo Musubi',
    email: 'equipo@uttt.edu.mx',
    campus: 'UTTT',
  ),
);

const luis = ReportSubject(
  id: 'u-luis',
  fullName: 'Luis Martínez',
  status: AccountStatus.active,
  upheldReports: 3,
  suspensionSuggested: true,
);

/// Reporte abierto de una publicacion (fixture `admin-report-page.json`).
AdminReport productReport({String id = 'r1'}) => AdminReport(
  id: id,
  reason: ReportReason.notAsDescribed,
  details: 'Las fotos son de otra tienda.',
  status: ReportStatus.open,
  createdAt: DateTime.utc(2026, 11, 16, 15),
  reporter: const AdminPerson(id: 'u-ana', fullName: 'Ana Sofía Ramírez'),
  target: const ReportedItem(
    kind: ReportedKind.product,
    id: 'p1',
    name: 'Calculadora Casio fx-991',
    status: 'active',
  ),
  subject: luis,
);

/// Reporte abierto desde Ajustes ("Reportar un problema").
AdminReport generalReport({String id = 'r2'}) => AdminReport(
  id: id,
  reason: ReportReason.other,
  status: ReportStatus.open,
  createdAt: DateTime.utc(2026, 11, 16, 14),
  reporter: const AdminPerson(id: 'u-ana', fullName: 'Ana Sofía Ramírez'),
  target: const ReportedItem(kind: ReportedKind.general),
);

AdminAccount luisAccount({AccountStatus status = AccountStatus.active}) =>
    AdminAccount(
      id: luis.id,
      fullName: luis.fullName,
      status: status,
      isAdmin: false,
      memberSince: DateTime.utc(2026, 10, 21),
      upheldReports: 3,
      suspensionSuggested: status == AccountStatus.active,
      history: [
        AdminLogEntry(
          action: 'report_upheld',
          at: DateTime.utc(2026, 11, 16, 16),
          actor: const AdminPerson(id: 'admin-1', fullName: 'Equipo Musubi'),
        ),
      ],
    );

/// Las categorias de la UTTT (fixture `admin-category-page.json`): las 6 de
/// la maqueta, con "Dibujo" desactivada.
List<AdminCategory> seedCategories() => [
  for (final (i, (slug, name)) in const [
    ('calculadoras', 'Calculadoras'),
    ('libros', 'Libros'),
    ('laptops', 'Laptops'),
    ('laboratorio', 'Laboratorio'),
    ('dibujo', 'Dibujo'),
    ('electronica', 'Electrónica'),
  ].indexed)
    AdminCategory(slug: slug, name: name, active: slug != 'dibujo', order: i),
];

/// Moderacion en memoria: cerrar un reporte lo pasa a "Revisados".
class FakeAdminRepository implements AdminRepository {
  new({
    List<AdminReport>? open,
    Map<String, AdminAccount>? accounts,
    List<AdminCategory>? categories,
  }) : openReports = open ?? [productReport(), generalReport()],
       accounts = accounts ?? {luis.id: luisAccount()},
       categoryList = categories ?? seedCategories();

  List<AdminReport> openReports;
  final closedReports = <AdminReport>[];
  Map<String, AdminAccount> accounts;
  final resolved = <(String, ReportAction, String?)>[];
  final suspensions = <(String, String)>[];
  final reactivations = <String>[];
  bool failLoad = false;
  ApiFailure? failResolve;
  ApiFailure? failSuspend;
  ApiFailure? failCategory;
  List<AdminCategory> categoryList;
  final categoryChanges = <(String, String?, bool?)>[];

  @override
  Future<List<AdminReport>> reports({required bool open}) async {
    if (failLoad) throw _offline;
    return [...(open ? openReports : closedReports)];
  }

  @override
  Future<AdminReport> resolve(
    String reportId,
    ReportAction action, {
    String? note,
  }) async {
    resolved.add((reportId, action, note));
    if (failResolve case final failure?) throw failure;
    final report = openReports.firstWhere((r) => r.id == reportId);
    openReports = [...openReports.where((r) => r.id != reportId)];
    final closed = AdminReport(
      id: report.id,
      reason: report.reason,
      details: report.details,
      status: action == ReportAction.uphold
          ? ReportStatus.upheld
          : ReportStatus.dismissed,
      createdAt: report.createdAt,
      reporter: report.reporter,
      target: report.target,
      subject: report.subject,
      review: ReportReview(
        at: DateTime.utc(2026, 11, 16, 16),
        reviewer: const AdminPerson(id: 'admin-1', fullName: 'Equipo Musubi'),
        note: note,
      ),
    );
    closedReports.insert(0, closed);
    return closed;
  }

  @override
  Future<List<SuspendedAccount>> suspended() async {
    if (failLoad) throw _offline;
    return [
      for (final a in accounts.values)
        if (a.status == AccountStatus.suspended)
          SuspendedAccount(
            id: a.id,
            fullName: a.fullName,
            suspendedAt: DateTime.utc(2026, 11, 16, 17),
          ),
    ];
  }

  @override
  Future<AdminAccount> account(String userId) async {
    if (failLoad) throw _offline;
    return accounts[userId] ?? (throw _notFound);
  }

  @override
  Future<AdminAccount> suspend(String userId, String reason) async {
    suspensions.add((userId, reason));
    if (failSuspend case final failure?) throw failure;
    return accounts[userId] = _with(userId, AccountStatus.suspended);
  }

  @override
  Future<AdminAccount> reactivate(String userId) async {
    reactivations.add(userId);
    return accounts[userId] = _with(userId, AccountStatus.active);
  }

  @override
  Future<List<AdminCategory>> categories() async {
    if (failLoad) throw _offline;
    return [...categoryList];
  }

  @override
  Future<AdminCategory> createCategory(String name) async {
    categoryChanges.add(('new', name, null));
    if (failCategory case final failure?) throw failure;
    final slug = name.toLowerCase().replaceAll(' ', '-');
    final created = AdminCategory(
      slug: slug,
      name: name,
      active: true,
      order: categoryList.length,
    );
    categoryList = [...categoryList, created];
    return created;
  }

  @override
  Future<AdminCategory> updateCategory(
    String slug, {
    String? name,
    bool? active,
  }) async {
    categoryChanges.add((slug, name, active));
    if (failCategory case final failure?) throw failure;
    final current = categoryList.firstWhere((c) => c.slug == slug);
    final updated = AdminCategory(
      slug: slug,
      name: name ?? current.name,
      active: active ?? current.active,
      order: current.order,
    );
    categoryList = [
      for (final c in categoryList)
        if (c.slug == slug) updated else c,
    ];
    return updated;
  }

  AdminAccount _with(String userId, AccountStatus status) {
    final a = accounts[userId]!;
    return AdminAccount(
      id: a.id,
      fullName: a.fullName,
      status: status,
      isAdmin: a.isAdmin,
      memberSince: a.memberSince,
      upheldReports: a.upheldReports,
      suspensionSuggested: false,
      history: a.history,
    );
  }

  static const _offline = ApiFailure(
    code: ApiFailure.networkOffline,
    message: 'No hay conexión. Revisa tu internet e inténtalo de nuevo.',
  );

  static const _notFound = ApiFailure(
    code: 'admin.account_not_found',
    message: 'No encontramos esa cuenta.',
  );
}
