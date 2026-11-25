import 'dart:async';

import 'package:musubi_app/core/storage/local_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Lo corre `flutter test` antes de cada archivo de pruebas.
///
/// HU-63: en la VM no hay plugin de Android, asi que la base local usa el motor
/// real de SQLite (`sqflite_common_ffi`, sin isolate para que funcione con el
/// reloj falso de las pruebas de pantallas), en memoria: cada almacen abre su
/// propia base vacia.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  sqfliteFfiInit();
  SqliteLocalStore.testFactory = databaseFactoryFfiNoIsolate;
  SqliteLocalStore.testPath = inMemoryDatabasePath;
  await testMain();
}
