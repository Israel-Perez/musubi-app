import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musubi_app/core/config/app_config.dart';
import 'package:musubi_app/core/network/api_client.dart';
import 'package:musubi_app/features/reputation/data/http_reputation_repository.dart';
import 'package:musubi_app/features/reputation/domain/reputation_models.dart';
import 'package:musubi_app/features/reputation/domain/reputation_repository.dart';

/// Reportar y bloquear (HU-28, HU-57), con sesion. En pruebas, un fake.
final reputationRepositoryProvider = Provider<ReputationRepository>(
  (ref) => HttpReputationRepository(
    ref.watch(dioProvider),
    ref.watch(appConfigProvider).apiBaseUrl,
  ),
);

/// "Usuarios bloqueados". Se vuelve a pedir al abrir la hoja.
final FutureProvider<List<BlockedUser>> blockedUsersProvider =
    FutureProvider.autoDispose<List<BlockedUser>>(
      (ref) => ref.watch(reputationRepositoryProvider).blocked(),
    );
