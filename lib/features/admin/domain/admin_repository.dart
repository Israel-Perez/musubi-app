import 'package:musubi_app/features/admin/domain/admin_models.dart';

/// Moderacion del campus y sus categorias (HU-39, HU-40 y HU-41). Solo para
/// el rol `admin`: la API responde 403 `auth.forbidden` a cualquier otra
/// cuenta.
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

  /// Las categorias del campus, tambien las desactivadas (HU-41).
  Future<List<AdminCategory>> categories();

  /// "Indicadores de uso" (HU-42): los del campus en el periodo.
  Future<UsageIndicators> indicators(IndicatorPeriod period);

  /// "Agregar categoría": activa y al final.
  Future<AdminCategory> createCategory(String name);

  /// Renombrar, desactivar o volver a activar; lo que viene en `null` no
  /// cambia.
  Future<AdminCategory> updateCategory(
    String slug, {
    String? name,
    bool? active,
  });
}
