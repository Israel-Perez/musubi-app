import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/features/listings/domain/listing_models.dart';
import 'package:musubi_app/features/listings/presentation/listings_providers.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';

/// Estado de la subida de una foto del borrador.
enum PhotoUpload { uploading, done, failed }

/// Foto del borrador: el archivo del telefono y, al subirse, su llave.
@immutable
class DraftPhoto {
  const new({
    required this.id,
    required this.path,
    this.key,
    this.upload = PhotoUpload.uploading,
  });

  /// Id local (estable al reordenar).
  final int id;
  final String path;
  final String? key;
  final PhotoUpload upload;

  DraftPhoto copyWith({String? key, PhotoUpload? upload}) => DraftPhoto(
    id: id,
    path: path,
    key: key ?? this.key,
    upload: upload ?? this.upload,
  );
}

/// Borrador de "Vender un producto" (maqueta `Vender-1…4`).
@immutable
class SellDraft {
  const new({
    this.photos = const [],
    this.title = '',
    this.description = '',
    this.category,
    this.priceCents = 0,
    this.condition = ProductCondition.used,
    this.usedDetail = UsedDetail.likeNew,
    this.quantity = 1,
    this.saved = false,
  });

  /// Maximo de fotos (maqueta: "Puedes subir hasta 8").
  static const maxPhotos = 8;

  /// Maximo de piezas (maqueta `Vender-4`).
  static const maxQuantity = 10;

  final List<DraftPhoto> photos;
  final String title;
  final String description;
  final String? category;
  final int priceCents;
  final ProductCondition condition;
  final UsedDetail usedDetail;
  final int quantity;

  /// "Guardar": se conserva al cerrar y se retoma desde Publicar.
  final bool saved;

  int get room => maxPhotos - photos.length;

  bool get titleValid => title.trim().length >= 3;

  /// Etiqueta de la vista previa ("Usado · Como nuevo · 1 disponible").
  String get summaryLabel {
    final detail = condition == ProductCondition.used
        ? usedDetail.label
        : 'Sin usar';
    final pieces = quantity == 1 ? '1 disponible' : '$quantity disponibles';
    return '${condition.label} · $detail · $pieces';
  }

  SellDraft copyWith({
    List<DraftPhoto>? photos,
    String? title,
    String? description,
    String? category,
    int? priceCents,
    ProductCondition? condition,
    UsedDetail? usedDetail,
    int? quantity,
    bool? saved,
  }) => SellDraft(
    photos: photos ?? this.photos,
    title: title ?? this.title,
    description: description ?? this.description,
    category: category ?? this.category,
    priceCents: priceCents ?? this.priceCents,
    condition: condition ?? this.condition,
    usedDetail: usedDetail ?? this.usedDetail,
    quantity: quantity ?? this.quantity,
    saved: saved ?? this.saved,
  );
}

/// Borrador vivo mientras dure la app: cada foto se sube en cuanto se agrega
/// y "Publicar producto" espera las que falten.
/// NOTE (HU-53): guardar el borrador con los datos locales para que
/// sobreviva a cerrar la app.
final sellDraftProvider = NotifierProvider<SellDraftNotifier, SellDraft>(
  SellDraftNotifier.new,
);

class SellDraftNotifier extends Notifier<SellDraft> {
  final Map<int, Future<void>> _uploads = {};
  int _nextId = 0;

  @override
  SellDraft build() => const SellDraft();

  /// "Vender un producto": empieza de cero salvo que haya un borrador
  /// guardado.
  void start() {
    if (!state.saved) state = const SellDraft();
  }

  void reset() => state = const SellDraft();

  /// "Guardar" (maqueta: "Borrador guardado").
  void save() => state = state.copyWith(saved: true);

  /// Agrega fotos (hasta 8) y empieza a subirlas. Devuelve cuantas entraron.
  int addPhotos(List<String> paths) {
    final accepted = paths.take(state.room).toList();
    final added = [
      for (final path in accepted) DraftPhoto(id: _nextId++, path: path),
    ];
    state = state.copyWith(photos: [...state.photos, ...added]);
    added.forEach(_upload);
    return accepted.length;
  }

  /// Quita una foto; devuelve su posicion para "Deshacer".
  (int, DraftPhoto)? removePhoto(int id) {
    final index = state.photos.indexWhere((p) => p.id == id);
    if (index < 0) return null;
    final photo = state.photos[index];
    state = state.copyWith(photos: [...state.photos]..removeAt(index));
    return (index, photo);
  }

  void restorePhoto(int index, DraftPhoto photo) {
    if (state.room <= 0) return;
    final photos = [...state.photos]
      ..insert(index.clamp(0, state.photos.length), photo);
    state = state.copyWith(photos: photos);
  }

  /// "Mantén presionada una foto para reordenarla".
  void movePhoto(int from, int to) {
    if (from == to) return;
    final photos = [...state.photos];
    final photo = photos.removeAt(from);
    photos.insert(to.clamp(0, photos.length), photo);
    state = state.copyWith(photos: photos);
  }

  void retry(int id) {
    final photo = state.photos.where((p) => p.id == id).firstOrNull;
    if (photo != null && photo.upload == PhotoUpload.failed) _upload(photo);
  }

  void setTitle(String value) => state = state.copyWith(title: value);

  void setDescription(String value) =>
      state = state.copyWith(description: value);

  void setCategory(String slug) => state = state.copyWith(category: slug);

  void setPrice(int cents) => state = state.copyWith(priceCents: cents);

  void setCondition(ProductCondition value) =>
      state = state.copyWith(condition: value);

  void setUsedDetail(UsedDetail value) =>
      state = state.copyWith(usedDetail: value);

  void step(int delta) => state = state.copyWith(
    quantity: (state.quantity + delta).clamp(1, SellDraft.maxQuantity),
  );

  /// Espera las fotos, reintenta las que fallaron y publica.
  Future<ProductSummary> publish() async {
    for (final photo in state.photos) {
      if (photo.upload == PhotoUpload.failed) _upload(photo);
    }
    await Future.wait([for (final photo in state.photos) ?_uploads[photo.id]]);
    final photos = state.photos;
    if (photos.isEmpty || photos.any((p) => p.key == null)) {
      throw const ApiFailure(
        code: ApiFailure.networkOffline,
        message: 'No pudimos subir todas tus fotos. Revisa tu conexión.',
      );
    }
    final draft = state;
    final product = await ref
        .read(listingsRepositoryProvider)
        .publish(
          NewListing(
            title: draft.title,
            description: draft.description,
            category: draft.category ?? '',
            priceCents: draft.priceCents,
            condition: draft.condition,
            usedDetail: draft.usedDetail,
            quantity: draft.quantity,
            photoKeys: [for (final p in photos) p.key!],
          ),
        );
    reset();
    return product;
  }

  void _upload(DraftPhoto photo) {
    _set(photo.id, (p) => p.copyWith(upload: PhotoUpload.uploading));
    _uploads[photo.id] = ref
        .read(listingsRepositoryProvider)
        .uploadPhoto(photo.path)
        .then(
          (uploaded) => _set(
            photo.id,
            (p) => p.copyWith(key: uploaded.key, upload: PhotoUpload.done),
          ),
          onError: (Object _) =>
              _set(photo.id, (p) => p.copyWith(upload: PhotoUpload.failed)),
        );
  }

  void _set(int id, DraftPhoto Function(DraftPhoto) change) {
    if (!ref.mounted) return;
    state = state.copyWith(
      photos: [
        for (final p in state.photos)
          if (p.id == id) change(p) else p,
      ],
    );
  }
}
