import 'package:flutter/foundation.dart';
import 'package:musubi_app/core/session/session_tokens.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';

// Reportar (HU-28) y bloquear (HU-57). Forma canonica: filas "M-13" de
// musubi-api `docs/endpoints.md`; aqui solo lo que usa la app.

/// Motivos de la maqueta (`REPORT_REASONS`), en su orden.
enum ReportReason {
  payment('payment', 'El pago no llegó o no coincide'),
  notAsDescribed('not_as_described', 'El producto no es como se describió'),
  noShow('no_show', 'La otra persona no llegó a la entrega'),
  offPlatform('off_platform', 'Me pidió pagar fuera de Musubi'),
  other('other', 'Otro problema');

  new(this.code, this.label);

  /// Valor de la API.
  final String code;

  /// Texto de la maqueta.
  final String label;

  /// `help` para "Otro problema" y `flag` para los demas (maqueta).
  MusubiIconData get icon =>
      this == other ? MusubiIcons.circleHelp : MusubiIcons.flag;
}

/// Lo que se reporta.
@immutable
sealed class ReportTarget {
  const new();
}

/// "Reportar un problema" desde Ajustes.
final class GeneralReport extends ReportTarget {
  const new();
}

/// "Reportar" desde el chat: la otra persona y la conversacion.
final class UserReport extends ReportTarget {
  const new({required this.userId, this.conversationId});

  final String userId;
  final String? conversationId;
}

/// Una persona en "Usuarios bloqueados".
@immutable
class BlockedUser {
  const new({
    required this.id,
    required this.name,
    required this.blockedAt,
    this.photoUrl,
  });

  final String id;
  final String name;
  final DateTime blockedAt;

  /// URL completa de su foto de perfil, o `null` (se ven sus iniciales).
  final String? photoUrl;

  String get initials => initialsOf(name);

  /// Nombre de pila ("Diego").
  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  /// Pareja de colores de sus iniciales: la misma que en el chat.
  int get palette => id.codeUnits.fold(0, (sum, unit) => sum + unit) % 5;
}

/// "¿Que destacas?" (maqueta `Calificar`, HU-27 y HU-45). A quien vende se le
/// ponen los cinco de la maqueta; a quien compra, los suyos (decision de la
/// usuaria del 12-Nov-2026).
enum RatingTag {
  onTime('on_time', 'Puntual'),
  asDescribed('as_described', 'Como se describió'),
  goodCommunication('good_communication', 'Buena comunicación'),
  fairPrice('fair_price', 'Precio justo'),
  friendly('friendly', 'Amable'),
  paidAsAgreed('paid_as_agreed', 'Pagó lo acordado');

  new(this.code, this.label);

  /// Valor de la API.
  final String code;

  /// Texto del chip.
  final String label;

  /// Los que se le ponen a quien vende (los califica quien compra).
  static const List<RatingTag> forSeller = [
    onTime,
    asDescribed,
    goodCommunication,
    fairPrice,
    friendly,
  ];

  /// Los que se le ponen a quien compra (los califica quien vende).
  static const List<RatingTag> forBuyer = [
    onTime,
    goodCommunication,
    friendly,
    paidAsAgreed,
  ];

  /// El chip de un codigo, o `null` si la app no lo conoce.
  static RatingTag? parse(Object? value) {
    for (final tag in values) {
      if (tag.code == value) return tag;
    }
    return null;
  }
}

/// Lo que dice la maqueta debajo de las estrellas (`RATE_TEXT`).
String ratingWords(int stars) => switch (stars) {
  1 => 'Muy mala',
  2 => 'Mala',
  3 => 'Regular',
  4 => 'Muy buena',
  _ => '¡Excelente!',
};

/// "Enviar calificacion".
@immutable
class NewRating {
  const new({required this.stars, this.tags = const [], this.comment});

  /// De 1 a 5.
  final int stars;
  final List<RatingTag> tags;

  /// "Cuentale a la comunidad", o `null`.
  final String? comment;
}

/// Una opinion de `Perfil-vendedor` ("Lo que dicen de Valeria").
@immutable
class Opinion {
  const new({
    required this.id,
    required this.stars,
    required this.raterName,
    required this.createdAt,
    this.tags = const [],
    this.comment,
  });

  final String id;
  final int stars;

  /// "Luis M.".
  final String raterName;
  final DateTime createdAt;
  final List<RatingTag> tags;
  final String? comment;
}

/// Una pagina de opiniones, de la mas nueva a la mas vieja.
@immutable
class OpinionPage {
  const new({this.items = const [], this.nextCursor});

  final List<Opinion> items;
  final String? nextCursor;
}
