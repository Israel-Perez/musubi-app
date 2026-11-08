import 'package:musubi_app/features/reputation/domain/reputation_models.dart';

/// Reportar (HU-28) y bloquear (HU-57), con sesion. Lanza `ApiFailure`
/// (nunca `DioException`).
abstract interface class ReputationRepository {
  /// "Enviar reporte". [details] es opcional ("Cuentanos que paso").
  Future<void> report(
    ReportTarget target,
    ReportReason reason, {
    String? details,
  });

  /// "Bloquear a …" (idempotente).
  Future<void> block(String userId);

  /// "Desbloquear" (idempotente).
  Future<void> unblock(String userId);

  /// "Usuarios bloqueados", del mas reciente al mas viejo.
  Future<List<BlockedUser>> blocked();
}
