import 'package:musubi_app/core/platform/email_inbox.dart';

/// Fake de [EmailInbox]: cuenta las aperturas; sin [available] no hay app de
/// correo en el telefono.
class FakeEmailInbox implements EmailInbox {
  new({this.available = true});

  bool available;
  int opened = 0;

  @override
  Future<bool> open() async {
    opened++;
    return available;
  }
}
