import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/features/reputation/domain/reputation_models.dart';
import 'package:musubi_app/features/reputation/domain/reputation_repository.dart';

/// Un reporte que recibio el fake.
typedef SentReport = ({
  ReportTarget target,
  ReportReason reason,
  String? details,
});

/// Reportar y bloquear en memoria: guarda lo que se le pide.
class FakeReputationRepository implements ReputationRepository {
  new({List<BlockedUser>? blockedUsers, this.reportFailure})
    : blockedUsers = blockedUsers ?? [];

  final List<BlockedUser> blockedUsers;
  ApiFailure? reportFailure;

  final List<SentReport> reports = [];
  final List<String> blockedIds = [];
  final List<String> unblockedIds = [];

  @override
  Future<void> report(
    ReportTarget target,
    ReportReason reason, {
    String? details,
  }) async {
    if (reportFailure != null) throw reportFailure!;
    reports.add((target: target, reason: reason, details: details));
  }

  @override
  Future<void> block(String userId) async => blockedIds.add(userId);

  @override
  Future<void> unblock(String userId) async {
    unblockedIds.add(userId);
    blockedUsers.removeWhere((u) => u.id == userId);
  }

  @override
  Future<List<BlockedUser>> blocked() async => List.of(blockedUsers);

  /// Calificaciones enviadas (HU-27, HU-45): pedido y calificacion.
  final List<(String, NewRating)> rated = [];

  /// Falla la siguiente calificacion.
  ApiFailure? rateFailure;

  /// Opiniones por persona (HU-27); "Ver más" pide la pagina de su cursor.
  final Map<String, List<Opinion>> opinionsByUser = {};

  /// Tamaño de pagina de las opiniones.
  int opinionsPageSize = 20;

  /// Falla la siguiente lectura de opiniones.
  ApiFailure? opinionsFailure;

  @override
  Future<void> rate(String orderId, NewRating rating) async {
    final failure = rateFailure;
    if (failure != null) {
      rateFailure = null;
      throw failure;
    }
    rated.add((orderId, rating));
  }

  @override
  Future<OpinionPage> opinions(String userId, {String? cursor}) async {
    final failure = opinionsFailure;
    if (failure != null) {
      opinionsFailure = null;
      throw failure;
    }
    final all = opinionsByUser[userId] ?? const <Opinion>[];
    final start = cursor == null
        ? 0
        : all.indexWhere((o) => o.id == cursor) + 1;
    final page = all.skip(start).take(opinionsPageSize).toList();
    final more = start + opinionsPageSize < all.length;
    return OpinionPage(items: page, nextCursor: more ? page.last.id : null);
  }
}
