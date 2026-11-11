import 'package:musubi_app/features/genai/domain/agreement_models.dart';

/// El acuerdo con IA de una conversacion (HU-32/33/34).
abstract interface class AgreementRepository {
  /// "Resumir acuerdo": la IA lee el chat y propone el acuerdo. Si la IA no
  /// esta disponible, `ApiFailure` con `genai.unavailable`.
  Future<Agreement> request(String conversationId);

  /// El acuerdo vigente de una conversacion, o `null`.
  Future<Agreement?> byConversation(String conversationId);

  /// Corrige la propuesta (borra las dos confirmaciones).
  Future<Agreement> update(Agreement agreement, AgreementEdit edit);

  /// "Confirmar acuerdo" sobre la version que se ve.
  Future<Agreement> confirm(Agreement agreement);

  /// Descarta el acuerdo para los dos.
  Future<void> discard(String id);
}
