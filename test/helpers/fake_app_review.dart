import 'package:musubi_app/core/platform/app_review.dart';

/// Fake de [AppReview]: cuenta los intentos y puede fallar como Play.
class FakeAppReview implements AppReview {
  new({this.result = true, this.fail = false});

  bool result;
  bool fail;
  int calls = 0;

  @override
  Future<bool> request() async {
    calls++;
    if (fail) throw StateError('Play no disponible');
    return result;
  }
}

/// La fecha del último aviso, en memoria.
class InMemoryReviewAskStore implements ReviewAskStore {
  new({this.at});

  DateTime? at;

  @override
  Future<DateTime?> askedAt() async => at;

  @override
  Future<void> markAsked(DateTime at) async => this.at = at;
}
