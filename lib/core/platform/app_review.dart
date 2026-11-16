import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// La reseña de la app en Google Play (HU-67). En pruebas, un fake.
abstract interface class AppReview {
  /// `true` si Google Play aceptó abrir el flujo; no dice si se mostró.
  Future<bool> request();
}

/// [AppReview] con el canal `musubi/review` de `MainActivity.kt`.
class PlatformAppReview implements AppReview {
  const new();

  static const _channel = MethodChannel('musubi/review');

  @override
  Future<bool> request() async {
    try {
      return await _channel.invokeMethod<bool>('requestReview') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}

/// En pruebas, un fake.
final appReviewProvider = Provider<AppReview>(
  (ref) => const PlatformAppReview(),
);

/// Si ya se pidió la reseña en este teléfono y cuándo (HU-67).
abstract interface class ReviewAskStore {
  Future<DateTime?> askedAt();

  Future<void> markAsked(DateTime at);
}

/// En el almacén cifrado del sistema, como la sesión.
class SecureReviewAskStore implements ReviewAskStore {
  new([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const key = 'musubi.review_asked_at';

  final FlutterSecureStorage _storage;

  @override
  Future<DateTime?> askedAt() async {
    final value = await _storage.read(key: key);
    return value == null ? null : DateTime.tryParse(value)?.toUtc();
  }

  @override
  Future<void> markAsked(DateTime at) =>
      _storage.write(key: key, value: at.toUtc().toIso8601String());
}

/// El registro del último aviso. En pruebas, uno en memoria.
final reviewAskStoreProvider = Provider<ReviewAskStore>(
  (ref) => SecureReviewAskStore(),
);

/// Pide la reseña como máximo una vez cada 90 días (HU-67). Si Play no está
/// disponible o falla, no avisa y no marca la fecha (RNF-15).
///
/// NOTE (HU-67): "primer pedido" es el primer aviso en este dispositivo; un
/// conteo exacto necesitaría `GET /orders/mine?tab=completed` (solo comprador)
/// o un campo de la API.
class ReviewPrompter {
  const new(this._review, this._store);

  static const window = Duration(days: 90);

  final AppReview _review;
  final ReviewAskStore _store;

  Future<void> maybeAsk({
    required DateTime now,
    required bool orderCompleted,
  }) async {
    if (!orderCompleted) return;
    try {
      final last = await _store.askedAt();
      if (last != null && now.toUtc().difference(last.toUtc()) < window) {
        return;
      }
      if (await _review.request()) await _store.markAsked(now.toUtc());
    } on Object catch (error) {
      debugPrint('Reseña no disponible: $error');
    }
  }
}

/// En `RateScreen`, al cerrar `Calificar` de un pedido completado.
final reviewPrompterProvider = Provider<ReviewPrompter>(
  (ref) => ReviewPrompter(
    ref.watch(appReviewProvider),
    ref.watch(reviewAskStoreProvider),
  ),
);
