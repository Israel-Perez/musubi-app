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
