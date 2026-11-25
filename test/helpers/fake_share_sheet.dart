import 'package:musubi_app/core/platform/share_sheet.dart';

/// Fake de [ShareSheet] (HU-61): guarda lo compartido y puede no tener app.
class FakeShareSheet implements ShareSheet {
  new({this.result = true});

  bool result;
  final List<ShareText> shared = [];

  @override
  Future<bool> share(ShareText content) async {
    shared.add(content);
    return result;
  }
}
