import 'package:musubi_app/core/session/session_api.dart';
import 'package:musubi_app/core/session/session_tokens.dart';

/// Fake de [SessionApi]: registra las revocaciones; sin [online] la API no
/// responde.
class FakeSessionApi implements SessionApi {
  new({this.online = true, this.renewed});

  final bool online;
  final SessionTokens? renewed;
  final List<String> revoked = [];

  @override
  Future<SessionTokens?> refresh(String refreshToken) async => renewed;

  @override
  Future<bool> revoke(String refreshToken) async {
    if (!online) return false;
    revoked.add(refreshToken);
    return true;
  }
}
