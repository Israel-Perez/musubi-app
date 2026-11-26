import 'package:dio/dio.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/features/admin/domain/admin_models.dart';
import 'package:musubi_app/features/admin/domain/admin_repository.dart';
import 'package:musubi_app/features/reputation/domain/reputation_models.dart';

/// Cliente HTTP de las filas "M-14" de musubi-api (HU-39, HU-40 y HU-41).
/// Fixtures `admin-report-page.json`, `admin-account.json`,
/// `admin-account-page.json`, `admin-category.json` y
/// `admin-category-page.json`.
class HttpAdminRepository implements AdminRepository {
  new(this._dio);

  final Dio _dio;

  @override
  Future<List<AdminReport>> reports({required bool open}) => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.adminReports,
      queryParameters: {'status': open ? 'open' : 'closed'},
    );
    return [for (final item in _items(response.data)) _report(item)];
  });

  @override
  Future<AdminReport> resolve(
    String reportId,
    ReportAction action, {
    String? note,
  }) => _guard(() async {
    final text = note?.trim();
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.adminReportResolution(reportId),
      data: {
        'action': action.code,
        if (text != null && text.isNotEmpty) 'note': text,
      },
    );
    return _report(_body(response.data));
  });

  @override
  Future<List<SuspendedAccount>> suspended() => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.adminSuspendedAccounts,
    );
    return [
      for (final item in _items(response.data))
        SuspendedAccount(
          id: item['id'] as String,
          fullName: item['fullName'] as String,
          suspendedAt: _date(item['updatedAt']),
        ),
    ];
  });

  @override
  Future<AdminAccount> account(String userId) => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.adminAccount(userId),
    );
    return _account(_body(response.data));
  });

  @override
  Future<AdminAccount> suspend(String userId, String reason) =>
      _guard(() async {
        final response = await _dio.post<Map<String, dynamic>>(
          ApiPaths.adminSuspension(userId),
          data: {'reason': reason.trim()},
        );
        return _account(_body(response.data));
      });

  @override
  Future<AdminAccount> reactivate(String userId) => _guard(() async {
    final response = await _dio.delete<Map<String, dynamic>>(
      ApiPaths.adminSuspension(userId),
    );
    return _account(_body(response.data));
  });

  @override
  Future<UsageIndicators> indicators(IndicatorPeriod period) =>
      _guard(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          ApiPaths.adminIndicators,
          queryParameters: {'period': period.code},
        );
        final body = response.data ?? const {};
        return UsageIndicators(
          period: IndicatorPeriod.values.firstWhere(
            (p) => p.code == body['period'],
            orElse: () => period,
          ),
          from: DateTime.parse(body['from'] as String),
          to: DateTime.parse(body['to'] as String),
          areas: [
            for (final area
                in (body['areas'] as List<dynamic>? ?? const [])
                    .cast<Map<String, dynamic>>())
              IndicatorArea(
                key: area['key'] as String,
                title: area['title'] as String,
                items: [
                  for (final item
                      in (area['items'] as List<dynamic>? ?? const [])
                          .cast<Map<String, dynamic>>())
                    _indicator(item),
                ],
              ),
          ],
        );
      });

  static UsageIndicator _indicator(Map<String, dynamic> item) => UsageIndicator(
    key: item['key'] as String,
    label: item['label'] as String,
    value: (item['value'] as num?)?.toDouble(),
    unit: IndicatorUnit.values.firstWhere(
      (u) => u.name == item['unit'],
      orElse: () => IndicatorUnit.count,
    ),
    detail: item['detail'] as String? ?? '',
    breakdown: [
      for (final part
          in (item['breakdown'] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>())
        IndicatorBreakdown(
          label: part['label'] as String,
          value: (part['value'] as num).toInt(),
        ),
    ],
  );

  @override
  Future<List<AdminCategory>> categories() => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.adminCategories,
    );
    return [for (final item in _items(response.data)) _category(item)];
  });

  @override
  Future<AdminCategory> createCategory(String name) => _guard(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.adminCategories,
      data: {'name': name.trim()},
    );
    return _category(_body(response.data));
  });

  @override
  Future<AdminCategory> updateCategory(
    String slug, {
    String? name,
    bool? active,
  }) => _guard(() async {
    final response = await _dio.patch<Map<String, dynamic>>(
      ApiPaths.adminCategory(slug),
      data: {'name': ?name?.trim(), 'active': ?active},
    );
    return _category(_body(response.data));
  });

  static AdminCategory _category(Map<String, dynamic> json) => AdminCategory(
    slug: json['slug'] as String,
    name: json['name'] as String,
    active: json['active'] as bool,
    order: (json['order'] as num).toInt(),
  );

  static AdminReport _report(Map<String, dynamic> json) {
    final target = json['target'] as Map<String, dynamic>;
    final subject = json['subject'] as Map<String, dynamic>?;
    final review = json['review'] as Map<String, dynamic>?;
    return AdminReport(
      id: json['id'] as String,
      reason: ReportReason.values.firstWhere(
        (r) => r.code == json['reason'],
        orElse: () => ReportReason.other,
      ),
      details: json['details'] as String?,
      status: ReportStatus.parse(json['status']),
      createdAt: _date(json['createdAt']),
      reporter: _person(json['reporter']),
      target: ReportedItem(
        kind: ReportedKind.parse(target['type']),
        id: target['id'] as String?,
        name: target['name'] as String?,
        photoUrl: target['photo'] as String?,
        status: target['status'] as String?,
      ),
      subject: subject == null
          ? null
          : ReportSubject(
              id: subject['id'] as String,
              fullName: subject['fullName'] as String,
              status: AccountStatus.parse(subject['status']),
              upheldReports: (subject['upheldReports'] as num).toInt(),
              suspensionSuggested: subject['suspensionSuggested'] as bool,
            ),
      review: review == null
          ? null
          : ReportReview(
              at: _date(review['at']),
              reviewer: _person(review['reviewer']),
              note: review['note'] as String?,
            ),
    );
  }

  static AdminAccount _account(Map<String, dynamic> json) => AdminAccount(
    id: json['id'] as String,
    fullName: json['fullName'] as String,
    status: AccountStatus.parse(json['status']),
    isAdmin: json['isAdmin'] as bool,
    memberSince: _date(json['memberSince']),
    upheldReports: (json['upheldReports'] as num).toInt(),
    suspensionSuggested: json['suspensionSuggested'] as bool,
    history: [
      for (final entry
          in (json['history'] as List).cast<Map<String, dynamic>>())
        AdminLogEntry(
          action: entry['action'] as String,
          at: _date(entry['at']),
          actor: _person(entry['actor']),
          reason: entry['reason'] as String?,
        ),
    ],
  );

  static AdminPerson? _person(Object? json) => json is Map<String, dynamic>
      ? AdminPerson(
          id: json['id'] as String,
          fullName: json['fullName'] as String,
        )
      : null;

  static List<Map<String, dynamic>> _items(Map<String, dynamic>? data) =>
      (_body(data)['items'] as List).cast<Map<String, dynamic>>();

  static Map<String, dynamic> _body(Map<String, dynamic>? data) =>
      data ?? (throw _unexpected);

  static DateTime _date(Object? value) => DateTime.parse('$value').toUtc();

  static const _unexpected = ApiFailure(
    code: ApiFailure.serverError,
    message: 'El servidor respondió algo inesperado.',
  );

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    }
  }
}
