import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:musubi_app/core/network/api_client.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/features/admin/data/http_admin_repository.dart';
import 'package:musubi_app/features/admin/domain/admin_models.dart';
import 'package:musubi_app/features/admin/domain/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => HttpAdminRepository(ref.watch(dioProvider)),
);

/// La sesion tiene el rol `admin` (HU-39): muestra "Administración" en
/// `Ajustes`. Sale del token, que se renueva cada 15 minutos.
final isAdminProvider = Provider<bool>(
  (ref) => switch (ref.watch(sessionControllerProvider)) {
    SignedIn(:final tokens) => tokens.isAdmin,
    Visitor() => false,
  },
);

/// Los reportes abiertos (`true`) o revisados (`false`). Sin reintento
/// automatico: la pantalla ofrece reintentar.
final FutureProviderFamily<List<AdminReport>, bool> adminReportsProvider =
    FutureProvider.autoDispose.family<List<AdminReport>, bool>(
      (ref, open) => ref.watch(adminRepositoryProvider).reports(open: open),
      retry: (_, _) => null,
    );

/// Las cuentas suspendidas del campus (HU-40).
final FutureProvider<List<SuspendedAccount>> suspendedAccountsProvider =
    FutureProvider.autoDispose<List<SuspendedAccount>>(
      (ref) => ref.watch(adminRepositoryProvider).suspended(),
      retry: (_, _) => null,
    );

/// Una cuenta con sus reportes procedentes y su historial (HU-40).
final FutureProviderFamily<AdminAccount, String> adminAccountProvider =
    FutureProvider.autoDispose.family<AdminAccount, String>(
      (ref, userId) => ref.watch(adminRepositoryProvider).account(userId),
      retry: (_, _) => null,
    );

/// Despues de moderar: las bandejas y la cuenta se vuelven a pedir.
void refreshModeration(WidgetRef ref, {String? userId}) {
  ref
    ..invalidate(adminReportsProvider)
    ..invalidate(suspendedAccountsProvider);
  if (userId != null) ref.invalidate(adminAccountProvider(userId));
}
