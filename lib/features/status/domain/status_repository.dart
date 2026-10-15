import 'package:musubi_app/features/status/domain/api_status.dart';

/// Consulta el estado de musubi-api (`GET /api/v1/ping`).
///
/// Contrato: nunca lanza por fallas de red; las traduce a [ApiOffline] para
/// que la UI no se rompa si la API no responde (01-03).
abstract interface class StatusRepository {
  Future<ApiStatus> check();
}
