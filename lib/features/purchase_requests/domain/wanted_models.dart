import 'package:flutter/foundation.dart';

// Solicitudes de compra "Se busca" (HU-13). Forma canonica: filas "M-05" de
// musubi-api `docs/endpoints.md`; aqui solo lo que muestra la app.

/// Estado de una solicitud.
enum WantedStatus {
  /// Recibe ofertas.
  active,

  /// Ya consiguio el producto (HU-14).
  closed,

  /// La cancelo quien la publico (HU-14).
  cancelled,

  /// Paso su fecha (RN-10).
  expired;

  /// Valor de la API.
  static WantedStatus parse(Object? value) => switch (value) {
    'closed' => WantedStatus.closed,
    'cancelled' => WantedStatus.cancelled,
    'expired' => WantedStatus.expired,
    _ => WantedStatus.active,
  };
}

/// Una solicitud publicada.
@immutable
class WantedRequest {
  const new({
    required this.id,
    required this.title,
    required this.categorySlug,
    required this.categoryName,
    required this.budgetCents,
    required this.quantity,
    required this.status,
    required this.requesterName,
    required this.createdAt,
    this.description,
    this.features = const [],
    this.neededBy,
    this.offersCount = 0,
  });

  final String id;
  final String title;
  final String categorySlug;
  final String categoryName;
  final String? description;
  final List<String> features;
  final int budgetCents;
  final int quantity;

  /// Dia en que la necesita (fecha local, sin hora), o `null`.
  final DateTime? neededBy;
  final WantedStatus status;
  final int offersCount;

  /// Nombre corto de quien busca ("Ana R.").
  final String requesterName;
  final DateTime createdAt;

  bool get isActive => status == WantedStatus.active;
}

/// Lo que se manda al publicar (`CreateWantedRequest`).
@immutable
class NewWanted {
  const new({
    required this.title,
    required this.category,
    required this.budgetCents,
    required this.quantity,
    this.description,
    this.features = const [],
    this.neededBy,
  });

  final String title;

  /// Slug de la categoria, u `otro`.
  final String category;
  final String? description;
  final List<String> features;
  final int budgetCents;
  final int quantity;
  final DateTime? neededBy;

  Map<String, Object?> toJson() => {
    'title': title.trim(),
    'category': category,
    'description': description?.trim().isEmpty ?? true
        ? null
        : description!.trim(),
    'features': features,
    'budgetCents': budgetCents,
    'quantity': quantity,
    'neededBy': neededBy == null ? null : apiDate(neededBy!),
  };
}

/// `2026-11-13` (la API recibe el dia, sin hora).
String apiDate(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';
