/// Intereses de la cuenta: slugs de categorías del campus (filas HU-66 de
/// musubi-api). Son privados: no salen en el perfil público.
abstract interface class InterestsRepository {
  Future<List<String>> get();

  /// Reemplaza los intereses; una lista vacía los borra.
  Future<List<String>> save(List<String> categories);
}
