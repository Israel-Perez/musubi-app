import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musubi_app/core/config/app_config.dart';
import 'package:musubi_app/core/network/etag_cache.dart';
import 'package:musubi_app/core/network/offline_cache.dart';
import 'package:musubi_app/core/observability/crash_reporter.dart';
import 'package:musubi_app/core/session/auth_interceptor.dart';
import 'package:musubi_app/core/session/session_api.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/core/storage/local_store.dart';

/// Timeouts del cliente HTTP. NOTE (02-05): ajustarlos con mediciones reales
/// contra la API desplegada (principio 6, empirico antes que teorico).
const apiConnectTimeout = Duration(seconds: 5);
const apiReceiveTimeout = Duration(seconds: 10);

/// Crea un cliente HTTP de musubi-api sin interceptores.
Dio createApiClient(AppConfig config) => Dio(
  BaseOptions(
    baseUrl: config.apiBaseUrl.toString(),
    connectTimeout: apiConnectTimeout,
    receiveTimeout: apiReceiveTimeout,
    headers: const {'Accept': 'application/json'},
  ),
);

/// Renovacion de la sesion: `POST /api/v1/auth/refresh` (HU-02) con
/// [publicDioProvider].
final sessionRefresherProvider = Provider<SessionRefresher>(
  (ref) => ref.watch(sessionApiProvider).refresh,
);

/// Cliente sin sesion: endpoints publicos de `/auth` y la renovacion del token
/// (asi la renovacion nunca pasa por el interceptor que la provoca).
final publicDioProvider = Provider<Dio>((ref) {
  final dio = createApiClient(ref.watch(appConfigProvider));
  // SCRUM-108: los 5xx y las fallas desconocidas, a Crashlytics.
  dio.interceptors.add(
    CrashReportingInterceptor(ref.watch(crashReporterProvider)),
  );
  ref.onDispose(dio.close);
  return dio;
});

/// Copias de las respuestas con `ETag` (02-06). Una por proceso.
final etagCacheProvider = Provider<EtagCache>((ref) => EtagCache());

/// Cliente con sesion: [OfflineCacheInterceptor] guarda en SQLite lo que se
/// abre sin conexion (HU-63), [EtagCacheInterceptor] revalida las listas con
/// su `ETag` (02-06) y [AuthInterceptor] agrega el token solo hacia la API y
/// renueva la sesion ante un 401.
final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final dio = createApiClient(config);
  final session = ref.read(sessionControllerProvider.notifier);
  final offline = OfflineCacheInterceptor(
    ref.watch(localStoreProvider),
    identity: () => switch (ref.read(sessionControllerProvider)) {
      SignedIn(:final tokens) => tokens.userId ?? 'sesion',
      Visitor() => 'visitante',
    },
    // Fuera del build de otros providers: el interceptor corre en la peticion.
    onOffline: ({required offline}) => Future.microtask(() {
      // La peticion puede terminar despues de cerrar la app (o la prueba).
      if (ref.mounted) ref.read(offlineProvider.notifier).set(offline: offline);
    }),
    onRefreshed: ref.read(offlineRefreshesProvider).add,
  )..fetch = dio.fetch;
  dio.interceptors
    // SCRUM-108: los 5xx y las fallas desconocidas, a Crashlytics.
    ..add(CrashReportingInterceptor(ref.watch(crashReporterProvider)))
    ..add(offline)
    ..add(
      EtagCacheInterceptor(
        ref.watch(etagCacheProvider),
        // El correo no cambia al renovar el token: la copia sigue sirviendo.
        identity: () => switch (ref.read(sessionControllerProvider)) {
          SignedIn(:final tokens) => tokens.profile?.email ?? 'sesion',
          Visitor() => '',
        },
      ),
    )
    ..add(
      AuthInterceptor(
        apiBaseUrl: config.apiBaseUrl,
        readTokens: () => switch (ref.read(sessionControllerProvider)) {
          SignedIn(:final tokens) => tokens,
          Visitor() => null,
        },
        onRefreshed: session.signIn,
        onSessionEnded: session.signOut,
        refresher: ref.watch(sessionRefresherProvider),
        retry: ref.watch(publicDioProvider).fetch,
      ),
    );
  ref.onDispose(dio.close);
  return dio;
});
