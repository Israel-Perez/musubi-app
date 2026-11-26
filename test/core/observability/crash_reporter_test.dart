import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/observability/crash_reporter.dart';

import '../../helpers/fake_http_adapter.dart';

/// SCRUM-108: lo que llega a Crashlytics no identifica a nadie (MASVS-PRIVACY)
/// y en debug y en las pruebas no sale nada.
void main() {
  group('CrashScrubber', () {
    test('quita correos, tokens, consultas, numeros largos y textos', () {
      final clean = CrashScrubber.text(
        'Fallo con ana.ramirez@uttt.edu.mx, Bearer abc.def.ghi, '
        'eyJhbGciOiJIUzI1.eyJzdWIiOiJ1MSJ9xx.firmaFirmaFirma en '
        '/api/v1/products?q=casio&campus=uttt al 7731234567 '
        'mensaje "nos vemos en la biblioteca"',
      );

      expect(clean, isNot(contains('ana.ramirez')));
      expect(clean, isNot(contains('abc.def.ghi')));
      expect(clean, isNot(contains('eyJ')));
      expect(clean, isNot(contains('casio')));
      expect(clean, isNot(contains('7731234567')));
      expect(clean, isNot(contains('biblioteca')));
      expect(clean, contains('[correo]'));
      expect(clean, contains('Bearer [token]'));
      expect(clean, contains('/api/v1/products?[consulta]'));
      expect(clean, contains('[numero]'));
      expect(clean, contains('"[texto]"'));
    });

    test('corta los mensajes largos y conserva el tipo', () {
      final error = CrashScrubber.error(StateError('x' * 1000));

      expect(error.type, 'StateError');
      expect(error.message.length, CrashScrubber.maxLength);
      expect(
        CrashScrubber.error(const ScrubbedError('ApiError', 'a@b.mx')).message,
        '[correo]',
      );
    });

    test('la ruta sin ids ni consulta', () {
      expect(
        CrashScrubber.path('/api/v1/products/6716a0000000000000000031?x=1'),
        '/api/v1/products/:id',
      );
      expect(
        CrashScrubber.path('/api/v1/orders/42/rating'),
        '/api/v1/orders/:id/rating',
      );
      expect(CrashScrubber.path('/api/v1/categories'), '/api/v1/categories');
    });
  });

  group('reportero', () {
    test('apagado no manda nada; en debug Firebase no se enciende', () async {
      const off = NoCrashReporter();
      // En las pruebas kReleaseMode es false: como un build de debug.
      final debug = FirebaseCrashReporter();

      await off.start();
      await debug.start();
      await debug.record(StateError('x'), null, fatal: true);

      expect(off.active, isFalse);
      expect(debug.active, isFalse);
    });
  });

  group('CrashReportingInterceptor', () {
    Future<List<ScrubbedError>> call(
      ResponseBody Function() respond, {
      bool active = true,
      DioExceptionType? fail,
    }) async {
      final reporter = _Recording(active: active);
      final dio = Dio(BaseOptions(baseUrl: 'https://api.musubi.example'))
        ..httpClientAdapter = FakeHttpAdapter((request) async {
          if (fail != null) {
            throw DioException(requestOptions: request, type: fail);
          }
          return respond();
        })
        ..interceptors.add(CrashReportingInterceptor(reporter));
      try {
        await dio.post<Object>(
          '/api/v1/products/6716a0000000000000000031?q=secreto',
          data: {'title': 'Mi calculadora', 'email': 'ana@uttt.edu.mx'},
        );
      } on DioException {
        // Se espera: el interceptor deja pasar el error.
      }
      return reporter.errors;
    }

    test(
      'un 5xx se manda con el metodo, la ruta sin ids y el codigo',
      () async {
        final errors = await call(
          () => FakeHttpAdapter.json({
            'code': 'server.error',
            'title': 'Algo salió mal.',
          }, status: 503),
        );

        final error = errors.single;
        expect(error.type, 'ApiError');
        expect(error.message, 'POST /api/v1/products/:id → 503 server.error');
        expect(error.message, isNot(contains('secreto')));
        expect(error.message, isNot(contains('ana@')));
      },
    );

    test('un 4xx, sin red o un timeout no se mandan', () async {
      final rejected = await call(
        () => FakeHttpAdapter.json({
          'code': 'listings.invalid_title',
        }, status: 400),
      );
      final offline = await call(
        () => FakeHttpAdapter.json({}),
        fail: DioExceptionType.connectionError,
      );
      final slow = await call(
        () => FakeHttpAdapter.json({}),
        fail: DioExceptionType.receiveTimeout,
      );

      expect([...rejected, ...offline, ...slow], isEmpty);
    });

    test('apagado no manda ni un 5xx', () async {
      final errors = await call(
        () => FakeHttpAdapter.json({'code': 'server.error'}, status: 500),
        active: false,
      );

      expect(errors, isEmpty);
    });
  });
}

class _Recording implements CrashReporter {
  new({required this.active});

  @override
  final bool active;

  final List<ScrubbedError> errors = [];

  @override
  Future<void> start() async {}

  @override
  Future<void> record(
    Object error,
    StackTrace? stack, {
    required bool fatal,
    String? reason,
  }) async {
    errors.add(error as ScrubbedError);
  }
}
