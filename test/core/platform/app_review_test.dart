import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/platform/app_review.dart';

import '../../helpers/fake_app_review.dart';

void main() {
  final now = DateTime.utc(2026, 11, 14, 18);

  ReviewPrompter prompter(FakeAppReview review, InMemoryReviewAskStore store) =>
      ReviewPrompter(review, store);

  group('ReviewPrompter (HU-67)', () {
    test('la primera vez pide la reseña y guarda la fecha', () async {
      final review = FakeAppReview();
      final store = InMemoryReviewAskStore();

      await prompter(review, store).maybeAsk(now: now, orderCompleted: true);

      expect(review.calls, 1);
      expect(store.at, now);
    });

    test('con menos de 90 días no vuelve a pedir', () async {
      final review = FakeAppReview();
      final store = InMemoryReviewAskStore()
        ..at = now.subtract(const Duration(days: 89));

      await prompter(review, store).maybeAsk(now: now, orderCompleted: true);

      expect(review.calls, 0);
      expect(store.at, now.subtract(const Duration(days: 89)));
    });

    test('a los 90 días exactos vuelve a pedir', () async {
      final review = FakeAppReview();
      final store = InMemoryReviewAskStore()
        ..at = now.subtract(const Duration(days: 90));

      await prompter(review, store).maybeAsk(now: now, orderCompleted: true);

      expect(review.calls, 1);
      expect(store.at, now);
    });

    test('si Play no está disponible no marca la fecha', () async {
      final review = FakeAppReview(result: false);
      final store = InMemoryReviewAskStore();

      await prompter(review, store).maybeAsk(now: now, orderCompleted: true);

      expect(review.calls, 1);
      expect(store.at, isNull);
    });

    test('si el servicio falla no propaga y no marca la fecha', () async {
      final review = FakeAppReview(fail: true);
      final store = InMemoryReviewAskStore();

      await prompter(review, store).maybeAsk(now: now, orderCompleted: true);

      expect(review.calls, 1);
      expect(store.at, isNull);
    });

    test('un pedido no completado no pide la reseña', () async {
      final review = FakeAppReview();
      final store = InMemoryReviewAskStore();

      await prompter(review, store).maybeAsk(now: now, orderCompleted: false);

      expect(review.calls, 0);
      expect(store.at, isNull);
    });
  });
}
