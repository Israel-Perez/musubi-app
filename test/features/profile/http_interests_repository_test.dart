import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/features/profile/data/http_interests_repository.dart';

import '../../helpers/fake_http_adapter.dart';

void main() {
  HttpInterestsRepository repositoryWith(FakeHttpAdapter adapter) =>
      HttpInterestsRepository(
        Dio(BaseOptions(baseUrl: 'https://api.musubi.example'))
          ..httpClientAdapter = adapter,
      );

  test('GET lee los slugs que guardó la API (HU-66)', () async {
    final adapter = FakeHttpAdapter(
      (_) async => FakeHttpAdapter.json({
        'categories': ['libros', 'laptops'],
      }),
    );

    final interests = await repositoryWith(adapter).get();

    expect(adapter.requests.single.path, ApiPaths.myInterests);
    expect(interests, ['libros', 'laptops']);
  });

  test('PUT envía la lista completa y devuelve la guardada', () async {
    final adapter = FakeHttpAdapter(
      (_) async => FakeHttpAdapter.json({
        'categories': ['dibujo'],
      }),
    );

    final interests = await repositoryWith(adapter).save(['dibujo']);

    expect(adapter.requests.single.method, 'PUT');
    expect(adapter.requests.single.path, ApiPaths.myInterests);
    expect(adapter.requests.single.data, {
      'categories': ['dibujo'],
    });
    expect(interests, ['dibujo']);
  });

  test('una forma inesperada es ApiFailure, no TypeError', () async {
    final adapter = FakeHttpAdapter(
      (_) async => FakeHttpAdapter.json({'categories': 'libros'}),
    );

    expect(repositoryWith(adapter).get(), throwsA(isA<ApiFailure>()));
  });

  test('un interés inválido llega con su código', () async {
    final adapter = FakeHttpAdapter(
      (_) async => FakeHttpAdapter.json({
        'code': 'profiles.invalid_interest',
        'title': 'Elige categorías de la lista.',
        'status': 400,
      }, status: 400),
    );

    await expectLater(
      repositoryWith(adapter).save(['motos']),
      throwsA(
        isA<ApiFailure>().having(
          (f) => f.code,
          'code',
          'profiles.invalid_interest',
        ),
      ),
    );
  });
}
