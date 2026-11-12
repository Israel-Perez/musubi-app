import 'package:flutter/foundation.dart';
import 'package:musubi_app/core/session/session_tokens.dart';

/// Como divide el campus sus estudios (`academicTerm` de la API): la UTTT
/// cursa 11 cuatrimestres. Cada campus define el suyo (RNF-21).
@immutable
class AcademicTerm {
  const new({required this.unit, required this.count});

  /// `cuatrimestre`, `semestre` o `trimestre`.
  final String unit;
  final int count;

  /// "6º cuatrimestre" (maqueta `Perfil`: "6º semestre").
  String label(int term) => '$termº $unit';

  @override
  bool operator ==(Object other) =>
      other is AcademicTerm && other.unit == unit && other.count == count;

  @override
  int get hashCode => Object.hash(unit, count);
}

/// Nivel de una carrera, para agrupar la lista.
enum CareerLevel {
  tsu('TSU'),
  engineering('Ingeniería'),
  bachelor('Licenciatura');

  new(this.label);

  /// Encabezado del grupo en la lista.
  final String label;

  static CareerLevel parse(String? value) => switch (value) {
    'engineering' => engineering,
    'bachelor' => bachelor,
    _ => tsu,
  };
}

/// Carrera del campus con su rango de periodos (TSU del 1 al 6; ingenieria y
/// licenciatura del 7 al 11 en la UTTT).
@immutable
class Career {
  const new({
    required this.slug,
    required this.name,
    required this.shortName,
    required this.firstTerm,
    required this.lastTerm,
    this.level = CareerLevel.tsu,
  });

  final String slug;

  /// Nombre oficial ("Ingeniería en Mecatrónica").
  final String name;

  /// Lo que muestra el perfil ("Ing. Mecatrónica").
  final String shortName;
  final int firstTerm;
  final int lastTerm;
  final CareerLevel level;

  /// Periodos validos de la carrera.
  List<int> get terms => [for (var t = firstTerm; t <= lastTerm; t++) t];

  bool allows(int term) => term >= firstTerm && term <= lastTerm;

  @override
  bool operator ==(Object other) => other is Career && other.slug == slug;

  @override
  int get hashCode => slug.hashCode;
}

/// Carreras del campus y su periodo (`GET /api/v1/careers`).
@immutable
class CareersCatalog {
  const new({required this.academicTerm, required this.careers});

  final AcademicTerm academicTerm;
  final List<Career> careers;

  /// Periodos validos sin carrera: del 1 al tope del campus.
  List<int> termsFor(Career? career) =>
      career?.terms ?? [for (var t = 1; t <= academicTerm.count; t++) t];
}

/// "Quien te ve" (maqueta `Privacidad`).
@immutable
class ProfileVisibility {
  const new({this.career = true, this.sales = true, this.online = false});

  final bool career;
  final bool sales;
  final bool online;

  ProfileVisibility copyWith({bool? career, bool? sales, bool? online}) =>
      ProfileVisibility(
        career: career ?? this.career,
        sales: sales ?? this.sales,
        online: online ?? this.online,
      );

  @override
  bool operator ==(Object other) =>
      other is ProfileVisibility &&
      other.career == career &&
      other.sales == sales &&
      other.online == online;

  @override
  int get hashCode => Object.hash(career, sales, online);
}

/// Estadisticas de `Perfil`. NOTE (HU-23)/NOTE (HU-27): las mueven los pedidos
/// y las calificaciones.
@immutable
class ProfileStats {
  const new({
    this.ratingAvg,
    this.ratingCount = 0,
    this.sales = 0,
    this.purchases = 0,
  });

  final double? ratingAvg;
  final int ratingCount;
  final int sales;
  final int purchases;
}

/// Mi perfil (`GET /api/v1/profiles/me`).
@immutable
class MyProfile {
  const new({
    required this.id,
    required this.fullName,
    required this.email,
    required this.campusShortName,
    required this.campusName,
    required this.academicTerm,
    this.emailVerifiedAt,
    this.career,
    this.term,
    this.photoUrl,
    this.visibility = const ProfileVisibility(),
    this.stats = const ProfileStats(),
  });

  final String id;
  final String fullName;
  final String email;
  final DateTime? emailVerifiedAt;

  /// Siglas ("UTTT").
  final String campusShortName;
  final String campusName;
  final AcademicTerm academicTerm;
  final Career? career;
  final int? term;

  /// URL completa de la foto, o `null` (se ven las iniciales).
  final String? photoUrl;
  final ProfileVisibility visibility;
  final ProfileStats stats;

  String get initials => initialsOf(fullName);

  /// "UTTT · Ing. Mecatrónica · 7º cuatrimestre". Con "Mostrar mi carrera"
  /// apagado solo el campus: la persona ve lo mismo que ve su campus.
  String get subtitle => [
    campusShortName,
    if (visibility.career && career != null) career!.shortName,
    if (visibility.career && term != null) academicTerm.label(term!),
  ].join(' · ');

  MyProfile copyWith({ProfileVisibility? visibility}) => MyProfile(
    id: id,
    fullName: fullName,
    email: email,
    emailVerifiedAt: emailVerifiedAt,
    campusShortName: campusShortName,
    campusName: campusName,
    academicTerm: academicTerm,
    career: career,
    term: term,
    photoUrl: photoUrl,
    visibility: visibility ?? this.visibility,
    stats: stats,
  );
}

const _months = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun', //
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic', //
];

/// "oct 2026" ("Desde" en la hoja "Correo institucional"), en hora local.
String monthYear(DateTime date) {
  final local = date.toLocal();
  return '${_months[local.month - 1]} ${local.year}';
}

/// Perfil publico de otra persona del campus (`GET /profiles/{id}`, HU-05):
/// cabecera de `Perfil-vendedor`. La tarjeta del vendedor en `Producto`
/// (HU-11) usa un subconjunto.
///
/// NOTE (HU-27): el promedio y las opiniones llegan con HU-27/HU-45; sin
/// calificaciones, `ratingAvg` es `null` y `ratingCount` es `0` (RN-26).
@immutable
class PublicProfile {
  const new({
    required this.id,
    required this.fullName,
    required this.campusShortName,
    required this.memberSince,
    required this.ratingCount,
    this.photoUrl,
    this.careerShortName,
    this.term,
    this.ratingAvg,
    this.sales,
  });

  final String id;
  final String fullName;

  /// Siglas del campus ("UTTT"); la API solo devuelve perfiles del campus.
  final String campusShortName;

  /// "En Musubi desde oct 2024": cuando verifico su correo o se creo la
  /// cuenta.
  final DateTime memberSince;

  final String? photoUrl;

  /// `null` si oculta su carrera ("Quien te ve", HU-04).
  final String? careerShortName;

  /// Periodo actual, o `null` si oculta la carrera.
  final int? term;

  final double? ratingAvg;
  final int ratingCount;

  /// `null` si oculta sus ventas.
  final int? sales;
}
