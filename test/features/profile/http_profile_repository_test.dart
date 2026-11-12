import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/features/profile/data/http_profile_repository.dart';
import 'package:musubi_app/features/profile/domain/profile_models.dart';

import '../../helpers/fake_http_adapter.dart';

/// `MyProfileResponse` como el fixture `my-profile.json` de musubi-api.
Map<String, Object?> myProfileJson({
  Map<String, Object?>? career,
  int? term,
  String? photo,
}) => {
  'id': '6716a0000000000000000001',
  'fullName': 'Ana Sofía Ramírez',
  'email': 'ana.ramirez@uttt.edu.mx',
  'emailVerifiedAt': '2026-10-21T12:00:00Z',
  'campus': {
    'shortName': 'UTTT',
    'name': 'Universidad Tecnológica de Tula-Tepeji',
  },
  'academicTerm': {'unit': 'cuatrimestre', 'count': 11},
  'career': career,
  'term': term,
  'photo': photo,
  'visibility': {'career': true, 'sales': true, 'online': false},
  'stats': {'ratingAvg': null, 'ratingCount': 0, 'sales': 0, 'purchases': 0},
};

/// `PublicProfileResponse` como el fixture `public-profile.json` de musubi-api.
Map<String, Object?> publicProfileJson({
  Map<String, Object?>? career,
  int? term,
  String? photo,
  double? ratingAvg,
  int ratingCount = 0,
  int? sales = 0,
}) => {
  'id': '6716a0000000000000000001',
  'fullName': 'Valeria Cruz',
  'campus': {
    'shortName': 'UTTT',
    'name': 'Universidad Tecnológica de Tula-Tepeji',
  },
  'photo': photo,
  'memberSince': '2024-10-01T12:00:00Z',
  'career': career,
  'term': term,
  'stats': {'ratingAvg': ratingAvg, 'ratingCount': ratingCount, 'sales': sales},
};

// HU-04: el repositorio habla las filas "M-02" de musubi-api
// (`docs/endpoints.md`) y traduce sus errores.
void main() {
  late FakeHttpAdapter adapter;
  late HttpProfileRepository repository;

  void serve(ResponseBody Function(RequestOptions options) response) {
    adapter = FakeHttpAdapter((options) async => response(options));
    repository = HttpProfileRepository(
      Dio(BaseOptions(baseUrl: 'https://api.musubi.example'))
        ..httpClientAdapter = adapter,
      Uri.parse('https://api.musubi.example'),
    );
  }

  test('mi perfil: mapea la cuenta, la carrera y la foto', () async {
    serve(
      (_) => FakeHttpAdapter.json(
        myProfileJson(
          career: {
            'slug': 'ing-mecatronica',
            'name': 'Ingeniería en Mecatrónica',
            'shortName': 'Ing. Mecatrónica',
            'firstTerm': 7,
            'lastTerm': 11,
          },
          term: 7,
          photo: '/media/avatars/6716a0000000000000000001/a.webp',
        ),
      ),
    );

    final me = await repository.me();

    expect(adapter.requests.single.path, ApiPaths.myProfile);
    expect(me.subtitle, 'UTTT · Ing. Mecatrónica · 7º cuatrimestre');
    expect(
      me.photoUrl,
      'https://api.musubi.example/media/avatars/6716a0000000000000000001/a.webp',
    );
    expect(me.emailVerifiedAt, DateTime.utc(2026, 10, 21, 12));
    expect(me.visibility, const ProfileVisibility());
    expect(me.stats.ratingAvg, isNull);
  });

  test(
    'datos personales: PUT con carrera y periodo (null los borra)',
    () async {
      serve((_) => FakeHttpAdapter.json(myProfileJson()));

      await repository.update(career: null, term: null);

      expect(adapter.requests.single.method, 'PUT');
      expect(adapter.requests.single.data, {'career': null, 'term': null});
    },
  );

  test('visibilidad: PUT con los tres interruptores', () async {
    serve((_) => FakeHttpAdapter.json(myProfileJson()));

    await repository.setVisibility(
      const ProfileVisibility(career: false, online: true),
    );

    expect(adapter.requests.single.path, ApiPaths.myProfileVisibility);
    expect(adapter.requests.single.data, {
      'career': false,
      'sales': true,
      'online': true,
    });
  });

  test('foto: PUT multipart con el campo photo; quitar es DELETE', () async {
    final dir = await Directory.systemTemp.createTemp('musubi-avatar');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/foto.jpg')..writeAsBytesSync([1, 2, 3]);
    serve(
      (options) => options.method == 'DELETE'
          ? ResponseBody.fromString('', 204)
          : FakeHttpAdapter.json(myProfileJson()),
    );

    await repository.uploadPhoto(file.path);
    await repository.removePhoto();

    final upload = adapter.requests.first;
    expect(upload.method, 'PUT');
    expect(upload.path, ApiPaths.myProfilePhoto);
    expect((upload.data as FormData).files.single.key, 'photo');
    expect(adapter.requests.last.method, 'DELETE');
  });

  test('carreras: el periodo del campus y la lista agrupable', () async {
    serve(
      (_) => FakeHttpAdapter.json({
        'academicTerm': {'unit': 'cuatrimestre', 'count': 11},
        'careers': [
          {
            'slug': 'lic-contaduria',
            'name': 'Licenciatura en Contaduría',
            'shortName': 'Lic. Contaduría',
            'level': 'bachelor',
            'firstTerm': 7,
            'lastTerm': 11,
          },
        ],
      }),
    );

    final catalog = await repository.careers();

    expect(catalog.academicTerm.count, 11);
    expect(catalog.careers.single.level, CareerLevel.bachelor);
    expect(catalog.careers.single.terms.first, 7);
  });

  group('perfil público (HU-05)', () {
    const id = '6716a0000000000000000001';

    test('mapea campus, carrera, periodo, "desde" y estadísticas', () async {
      serve(
        (_) => FakeHttpAdapter.json(
          publicProfileJson(
            career: {
              'slug': 'ing-mecatronica',
              'name': 'Ingeniería en Mecatrónica',
              'shortName': 'Ing. Mecatrónica',
              'firstTerm': 7,
              'lastTerm': 11,
            },
            term: 7,
            photo: '/media/avatars/6716a0000000000000000001/a.webp',
            ratingAvg: 4.6,
            ratingCount: 18,
            sales: 15,
          ),
        ),
      );

      final profile = await repository.publicProfile(id);

      expect(adapter.requests.single.path, ApiPaths.publicProfile(id));
      expect(profile.fullName, 'Valeria Cruz');
      expect(profile.campusShortName, 'UTTT');
      expect(profile.memberSince, DateTime.utc(2024, 10, 1, 12));
      expect(profile.careerShortName, 'Ing. Mecatrónica');
      expect(profile.term, 7);
      expect(
        profile.photoUrl,
        'https://api.musubi.example/media/avatars/'
        '6716a0000000000000000001/a.webp',
      );
      expect(profile.ratingAvg, 4.6);
      expect(profile.ratingCount, 18);
      expect(profile.sales, 15);
    });

    test('sin calificaciones ni ventas visibles, y carrera oculta', () async {
      serve((_) => FakeHttpAdapter.json(publicProfileJson(sales: null)));

      final profile = await repository.publicProfile(id);

      expect(profile.ratingAvg, isNull);
      expect(profile.ratingCount, 0);
      expect(profile.sales, isNull);
      expect(profile.careerShortName, isNull);
      expect(profile.term, isNull);
    });

    test('404 profiles.not_found se traduce a ApiFailure', () async {
      serve(
        (_) => FakeHttpAdapter.json({
          'code': 'profiles.not_found',
          'title': 'No encontramos ese perfil.',
          'status': 404,
        }, status: 404),
      );

      await expectLater(
        repository.publicProfile(id),
        throwsA(
          isA<ApiFailure>()
              .having((f) => f.code, 'code', 'profiles.not_found')
              .having((f) => f.message, 'message', 'No encontramos ese perfil.')
              .having((f) => f.status, 'status', 404),
        ),
      );
    });

    test('una forma inesperada se traduce a ApiFailure', () async {
      serve((_) => FakeHttpAdapter.json({'id': id}));

      await expectLater(
        repository.publicProfile(id),
        throwsA(
          isA<ApiFailure>()
              .having((f) => f.code, 'code', ApiFailure.serverError)
              .having(
                (f) => f.message,
                'message',
                'El servidor respondió algo inesperado.',
              ),
        ),
      );
    });
  });

  test('error del back: ApiFailure con su codigo en espanol', () async {
    serve(
      (_) => FakeHttpAdapter.json({
        'code': 'profiles.invalid_term',
        'title': 'Elige un periodo que corresponda a tu carrera.',
        'status': 400,
      }, status: 400),
    );

    await expectLater(
      repository.update(career: 'tsu-ti-software', term: 9),
      throwsA(
        isA<ApiFailure>()
            .having((f) => f.code, 'code', 'profiles.invalid_term')
            .having(
              (f) => f.message,
              'message',
              'Elige un periodo que corresponda a tu carrera.',
            ),
      ),
    );
  });
}
