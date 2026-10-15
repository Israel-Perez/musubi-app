import 'dart:async';

import 'package:musubi_app/features/status/domain/api_status.dart';
import 'package:musubi_app/features/status/domain/status_repository.dart';

/// Fake de [StatusRepository] (skill `deferred-scope-fakes`): devuelve los
/// resultados en orden (repite el ultimo) y cuenta las llamadas.
class FakeStatusRepository implements StatusRepository {
  new(this._results) : _pending = null;

  /// Nunca responde: sirve para probar el estado "cargando".
  new pending() : _results = const [], _pending = Completer<ApiStatus>();

  final List<ApiStatus> _results;
  final Completer<ApiStatus>? _pending;
  int calls = 0;

  @override
  Future<ApiStatus> check() {
    calls++;
    final pending = _pending;
    if (pending != null) {
      return pending.future;
    }
    final index = calls - 1 < _results.length ? calls - 1 : _results.length - 1;
    return Future.value(_results[index]);
  }
}
