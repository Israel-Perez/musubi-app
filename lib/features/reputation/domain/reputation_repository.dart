import 'package:musubi_app/features/reputation/domain/reputation_models.dart';

/// Reportar (HU-28), bloquear (HU-57) y calificar (HU-27, HU-45), con
/// sesion. Lanza `ApiFailure` (nunca `DioException`).
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

  /// "Enviar calificacion" de un pedido completado (HU-27, HU-45).
  Future<void> rate(String orderId, NewRating rating);

  /// "Opiniones" del perfil de una persona; [cursor] pide la siguiente
  /// pagina.
  Future<OpinionPage> opinions(String userId, {String? cursor});
}
