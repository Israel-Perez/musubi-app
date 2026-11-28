import 'package:musubi_app/core/platform/web_page.dart';

/// Fake de [WebPage] (SCRUM-127): guarda lo que se abrio y puede no tener
/// navegador.
class FakeWebPage implements WebPage {
  new({this.result = true});

  bool result;
  final List<String> opened = [];

  @override
  Future<bool> open(String url) async {
    opened.add(url);
    return result;
  }
}
