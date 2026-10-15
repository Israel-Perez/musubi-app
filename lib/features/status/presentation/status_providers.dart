import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musubi_app/core/network/api_client.dart';
import 'package:musubi_app/features/status/data/http_status_repository.dart';
import 'package:musubi_app/features/status/domain/api_status.dart';
import 'package:musubi_app/features/status/domain/status_repository.dart';

/// Repositorio del estado de la API (en pruebas se sobrescribe con un fake).
final statusRepositoryProvider = Provider<StatusRepository>(
  (ref) => HttpStatusRepository(ref.watch(dioProvider)),
);

/// Estado actual de la API.
/// Para reintentar: `ref.invalidate(apiStatusProvider)`.
final FutureProvider<ApiStatus> apiStatusProvider =
    FutureProvider.autoDispose<ApiStatus>(
      (ref) => ref.watch(statusRepositoryProvider).check(),
    );
