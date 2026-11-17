import 'package:musubi_app/features/admin/domain/admin_models.dart';

/// Moderacion del campus (HU-39 y HU-40). Solo para el rol `admin`: la API
/// responde 403 `auth.forbidden` a cualquier otra cuenta.
abstract interface class AdminRepository {
  /// Los reportes abiertos ([open]) o los revisados, del mas nuevo al mas
  /// viejo.
  Future<List<AdminReport>> reports({required bool open});

  /// "Descartar" o "Procedente" (con una publicacion, la retira).
  Future<AdminReport> resolve(
    String reportId,
    ReportAction action, {
    String? note,
  });

  /// Las cuentas suspendidas del campus.
  Future<List<SuspendedAccount>> suspended();

  /// Una cuenta con sus reportes procedentes y su historial.
  Future<AdminAccount> account(String userId);

  /// "Suspender cuenta" con su motivo.
  Future<AdminAccount> suspend(String userId, String reason);

  /// "Reactivar cuenta".
  Future<AdminAccount> reactivate(String userId);
}
