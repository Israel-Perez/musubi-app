import 'package:dio/dio.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/features/marketplace/data/product_json.dart';
import 'package:musubi_app/features/profile/domain/profile_models.dart';
import 'package:musubi_app/features/profile/domain/profile_repository.dart';

/// [ProfileRepository] sobre las filas "M-02" de
/// `musubi-api/docs/endpoints.md` (spec `musubi-api:HU-04`). Usa el cliente
/// con sesion.
class HttpProfileRepository implements ProfileRepository {
  new(this._dio, this._apiBaseUrl);

  final Dio _dio;
  final Uri _apiBaseUrl;

  @override
  Future<MyProfile> me() => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>(ApiPaths.myProfile);
    return _profile(response);
  });

  @override
  Future<MyProfile> update({required String? career, required int? term}) =>
      _guard(() async {
        final response = await _dio.put<Map<String, dynamic>>(
          ApiPaths.myProfile,
          data: {'career': career, 'term': term},
        );
        return _profile(response);
      });

  @override
  Future<MyProfile> setVisibility(ProfileVisibility visibility) =>
      _guard(() async {
        final response = await _dio.put<Map<String, dynamic>>(
          ApiPaths.myProfileVisibility,
          data: {
            'career': visibility.career,
            'sales': visibility.sales,
            'online': visibility.online,
          },
        );
        return _profile(response);
      });

  @override
  Future<MyProfile> uploadPhoto(String filePath) => _guard(() async {
    final form = FormData.fromMap({
      'photo': await MultipartFile.fromFile(filePath),
    });
    final response = await _dio.put<Map<String, dynamic>>(
      ApiPaths.myProfilePhoto,
      data: form,
    );
    return _profile(response);
  });

  @override
  Future<void> removePhoto() =>
      _guard(() => _dio.delete<void>(ApiPaths.myProfilePhoto));

  @override
  Future<CareersCatalog> careers() => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>(ApiPaths.careers);
    final body = _body(response);
    return CareersCatalog(
      academicTerm: _term(body['academicTerm']),
      careers: [
        for (final item
            in (body['careers'] as List<dynamic>? ?? const [])
                .cast<Map<String, dynamic>>())
          _career(item)!,
      ],
    );
  });

  MyProfile _profile(Response<Map<String, dynamic>> response) {
    final json = _body(response);
    final campus = json['campus'] as Map<String, dynamic>;
    final visibility = json['visibility'] as Map<String, dynamic>;
    final stats = json['stats'] as Map<String, dynamic>;
    final photo = json['photo'] as String?;
    final verifiedAt = json['emailVerifiedAt'] as String?;
    return MyProfile(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      emailVerifiedAt: verifiedAt == null
          ? null
          : DateTime.parse(verifiedAt).toUtc(),
      campusShortName: campus['shortName'] as String,
      campusName: campus['name'] as String,
      academicTerm: _term(json['academicTerm']),
      career: _career(json['career'] as Map<String, dynamic>?),
      term: json['term'] as int?,
      photoUrl: photo == null ? null : mediaUrl(photo, _apiBaseUrl),
      visibility: ProfileVisibility(
        career: visibility['career'] as bool,
        sales: visibility['sales'] as bool,
        online: visibility['online'] as bool,
      ),
      stats: ProfileStats(
        ratingAvg: (stats['ratingAvg'] as num?)?.toDouble(),
        ratingCount: stats['ratingCount'] as int,
        sales: stats['sales'] as int,
        purchases: stats['purchases'] as int,
      ),
    );
  }

  static AcademicTerm _term(Object? json) {
    final term = json! as Map<String, dynamic>;
    return AcademicTerm(
      unit: term['unit'] as String,
      count: term['count'] as int,
    );
  }

  static Career? _career(Map<String, dynamic>? json) => json == null
      ? null
      : Career(
          slug: json['slug'] as String,
          name: json['name'] as String,
          shortName: json['shortName'] as String,
          firstTerm: json['firstTerm'] as int,
          lastTerm: json['lastTerm'] as int,
          level: CareerLevel.parse(json['level'] as String?),
        );

  static Map<String, dynamic> _body(Response<Map<String, dynamic>> response) =>
      response.data ??
      (throw const ApiFailure(
        code: ApiFailure.serverError,
        message: 'El servidor respondió algo inesperado.',
      ));

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (error) {
      // Se traduce (no se traga): la pantalla decide por el code.
      throw ApiFailure.fromDio(error);
    }
  }
}
