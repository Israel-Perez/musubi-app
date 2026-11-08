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
}
