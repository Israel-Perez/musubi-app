import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:musubi_app/core/network/api_client.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/features/admin/data/http_admin_repository.dart';
import 'package:musubi_app/features/admin/domain/admin_models.dart';
import 'package:musubi_app/features/admin/domain/admin_repository.dart';
import 'package:musubi_app/features/listings/presentation/listings_providers.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';

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

/// Las categorias del campus, tambien las desactivadas (HU-41).
final FutureProvider<List<AdminCategory>> adminCategoriesProvider =
    FutureProvider.autoDispose<List<AdminCategory>>(
      (ref) => ref.watch(adminRepositoryProvider).categories(),
      retry: (_, _) => null,
    );

/// Despues de cambiar una categoria: "Categorías", `Vender-3`, "Filtrar" e
/// "Intereses" la vuelven a pedir.
void refreshCategories(WidgetRef ref) {
  ref
    ..invalidate(adminCategoriesProvider)
    ..invalidate(categoriesProvider)
    ..invalidate(sellCategoriesProvider);
}

/// "Indicadores de uso" del campus por periodo (HU-42). Sin reintento
/// automatico: la pantalla ofrece reintentar.
final FutureProviderFamily<UsageIndicators, IndicatorPeriod>
adminIndicatorsProvider = FutureProvider.autoDispose
    .family<UsageIndicators, IndicatorPeriod>(
      (ref, period) => ref.watch(adminRepositoryProvider).indicators(period),
      retry: (_, _) => null,
    );
