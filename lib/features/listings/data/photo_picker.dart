import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// No se pudo abrir la camara o la galeria (sin camara, permiso negado).
class PhotoPickFailure implements Exception {
  const new(this.message);

  final String message;

  @override
  String toString() => 'PhotoPickFailure: $message';
}

/// Camara y galeria del telefono (maqueta `Vender-1`). Devuelve rutas de
/// archivos ya reducidos (RNF-13): la API los vuelve a procesar.
abstract interface class PhotoPicker {
  /// Una foto de la camara, o `null` si la persona cancela.
  Future<String?> takePhoto();

  /// Hasta [max] fotos de la galeria (lista vacia si cancela).
  Future<List<String>> pickFromGallery({required int max});
}

/// [PhotoPicker] con `image_picker` (flutter.dev): la camara del sistema y el
/// selector de fotos de Android, sin pedir permisos a la app.
/// NOTE (HU-06): recuperar la foto con `retrieveLostData` si Android cierra
/// la app mientras la camara esta abierta.
class ImagePickerPhotoPicker implements PhotoPicker {
  new([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Lado mayor con el que sale del telefono (igual al que guarda la API).
  static const maxSide = 1600.0;

  /// Calidad JPEG al reducir.
  static const quality = 85;

  @override
  Future<String?> takePhoto() => _guard(() async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: maxSide,
      maxHeight: maxSide,
      imageQuality: quality,
      requestFullMetadata: false,
    );
    return photo?.path;
  });

  @override
  Future<List<String>> pickFromGallery({required int max}) => _guard(() async {
    if (max <= 0) return const <String>[];
    // `pickMultiImage` exige un limite de 2 o mas.
    if (max == 1) {
      final photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxSide,
        maxHeight: maxSide,
        imageQuality: quality,
        requestFullMetadata: false,
      );
      return [?photo?.path];
    }
    final photos = await _picker.pickMultiImage(
      maxWidth: maxSide,
      maxHeight: maxSide,
      imageQuality: quality,
      limit: max,
      requestFullMetadata: false,
    );
    return [for (final photo in photos.take(max)) photo.path];
  });

  static Future<T> _guard<T>(Future<T> Function() pick) async {
    try {
      return await pick();
    } on PlatformException catch (error) {
      // Se traduce para la pantalla (sin camara, permiso negado, etc.).
      throw PhotoPickFailure(error.message ?? error.code);
    }
  }
}
