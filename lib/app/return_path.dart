import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musubi_app/app/router.dart';

/// "Al terminar, te regresamos a donde estabas" (maqueta, modo visitante):
/// la pantalla desde la que el visitante abrio "Crea tu cuenta". Se consume
/// al terminar el registro (bienvenida) o al iniciar sesion.
final returnPathProvider = NotifierProvider<ReturnPath, String?>(
  ReturnPath.new,
);

class ReturnPath extends Notifier<String?> {
  @override
  String? build() => null;

  /// Recuerda a donde volver (solo rutas internas conocidas).
  void remember(String location) {
    state = Uri.tryParse(location)?.path;
  }

  /// Ruta segura a la que volver; la olvida despues de usarla.
  String take() {
    final target = AppRoutes.safeReturn(state);
    state = null;
    return target;
  }
}
