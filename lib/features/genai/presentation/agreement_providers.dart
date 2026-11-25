import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:musubi_app/core/network/api_client.dart';
import 'package:musubi_app/features/chat/presentation/chat_providers.dart';
import 'package:musubi_app/features/genai/data/http_agreement_repository.dart';
import 'package:musubi_app/features/genai/domain/agreement_models.dart';
import 'package:musubi_app/features/genai/domain/agreement_repository.dart';

/// El acuerdo con IA (HU-32/33/34). En pruebas, un fake.
final agreementRepositoryProvider = Provider<AgreementRepository>(
  (ref) => HttpAgreementRepository(ref.watch(dioProvider)),
);

/// El acuerdo vigente de una conversacion, o `null`. Se vuelve a pedir cuando
/// el hub avisa que cambio (`agreementChanged`).
final FutureProviderFamily<Agreement?, String> agreementProvider =
    FutureProvider.autoDispose.family<Agreement?, String>((
      ref,
      conversationId,
    ) {
      ref.listen(chatAgreementChangesProvider, (_, next) {
        if (next.value == conversationId) ref.invalidateSelf();
      });
      return ref
          .watch(agreementRepositoryProvider)
          .byConversation(conversationId);
    }, retry: (_, _) => null);

/// Si la persona ya vio el aviso de la IA (RN-40): se muestra solo la primera
/// vez en este dispositivo.
abstract interface class AiNoticeStore {
  Future<bool> seen();

  Future<void> markSeen();
}

/// En el almacen cifrado del sistema, como la sesion.
class SecureAiNoticeStore implements AiNoticeStore {
  new([FlutterSecureStorage? storage, this.entry = key])
    : _storage = storage ?? const FlutterSecureStorage();

  static const key = 'musubi.ai_notice_seen';

  /// HU-59: el aviso de "Llenar con IA", que envia otra cosa (la foto).
  static const photoKey = 'musubi.photo_ai_notice_seen';

  final FlutterSecureStorage _storage;

  /// La entrada del almacen de este aviso.
  final String entry;

  @override
  Future<bool> seen() async => await _storage.read(key: entry) == '1';

  @override
  Future<void> markSeen() => _storage.write(key: entry, value: '1');
}

/// El aviso de la IA. En pruebas, uno en memoria.
final aiNoticeStoreProvider = Provider<AiNoticeStore>(
  (ref) => SecureAiNoticeStore(),
);

/// El aviso de "Llenar con IA" (HU-59): la primera vez se explica que la
/// portada se envia a la IA. En pruebas, uno en memoria.
final photoAiNoticeStoreProvider = Provider<AiNoticeStore>(
  (ref) => SecureAiNoticeStore(null, SecureAiNoticeStore.photoKey),
);
