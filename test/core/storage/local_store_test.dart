import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/storage/local_store.dart';
import 'package:sqflite/sqflite.dart' show databaseFactorySqflitePlugin;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// HU-63 (L-16h): la base SQLite del telefono, con el motor real de SQLite
/// (`sqflite_common_ffi`) en una base en memoria.
void main() {
  sqfliteFfiInit();
  var now = DateTime.utc(2026, 11, 23, 18);

  SqliteLocalStore store() => SqliteLocalStore(
    factory: databaseFactoryFfiNoIsolate,
    path: inMemoryDatabasePath,
    clock: () => now,
  );

  OutboxItem item(String id, String user, DateTime at) => OutboxItem(
    id: id,
    userId: user,
    conversationId: 'c1',
    text: 'Hola $id',
    createdAt: at,
  );

  setUp(() => now = DateTime.utc(2026, 11, 23, 18));

  test('guarda y reemplaza la respuesta de una llave', () async {
    final db = store();

    expect(await db.read('u1|/api/v1/conversations'), isNull);
    await db.write('u1|/api/v1/conversations', '{"items":[]}');
    await db.write('u1|/api/v1/conversations', '{"items":[1]}');

    expect(await db.read('u1|/api/v1/conversations'), '{"items":[1]}');
    expect(await db.read('u2|/api/v1/conversations'), isNull);
  });

  test('los mensajes por enviar son de cada persona, del mas viejo al mas '
      'nuevo, y se quitan al salir', () async {
    final db = store();
    await db.enqueue(item('b', 'u1', now.add(const Duration(minutes: 2))));
    await db.enqueue(item('a', 'u1', now));
    await db.enqueue(item('x', 'u2', now));

    expect([for (final i in await db.outbox('u1')) i.id], ['a', 'b']);
    await db.dequeue('a');

    final left = await db.outbox('u1');
    expect([for (final i in left) i.id], ['b']);
    expect(
      (left.single.text, left.single.createdAt),
      ('Hola b', now.add(const Duration(minutes: 2))),
    );
  });

  test('cerrar sesion lo borra todo (MASVS-STORAGE)', () async {
    final db = store();
    await db.write('u1|/api/v1/orders/mine', '{}');
    await db.enqueue(item('a', 'u1', now));

    await db.clear();

    expect(await db.read('u1|/api/v1/orders/mine'), isNull);
    expect(await db.outbox('u1'), isEmpty);
  });

  test('al abrir borra respuestas de mas de 30 dias y mensajes de mas de '
      '7', () async {
    final factory = databaseFactoryFfiNoIsolate;
    final path = '${await factory.getDatabasesPath()}/hu63_retention.db';
    await factory.deleteDatabase(path);
    final first = SqliteLocalStore(
      factory: factory,
      path: path,
      clock: () => now,
    );
    await first.write('vieja', '{}');
    await first.enqueue(item('viejo', 'u1', now));
    now = now.add(const Duration(days: 31));
    await first.write('nueva', '{}');
    await first.enqueue(item('nuevo', 'u1', now));

    final reopened = SqliteLocalStore(
      factory: factory,
      path: path,
      clock: () => now,
    );

    expect(await reopened.read('vieja'), isNull);
    expect(await reopened.read('nueva'), '{}');
    expect([for (final i in await reopened.outbox('u1')) i.id], ['nuevo']);
    await factory.deleteDatabase(path);
  });

  test('sin el plugin de SQLite se comporta vacia y la app sigue', () async {
    // En la VM no hay plugin de Android: el factory de sqflite falla.
    TestWidgetsFlutterBinding.ensureInitialized();
    final db = SqliteLocalStore(
      factory: databaseFactorySqflitePlugin,
      path: 'no-existe.db',
    );

    await db.write('llave', '{}');

    expect(await db.read('llave'), isNull);
    expect(await db.outbox('u1'), isEmpty);
  });

  test('si la base no abre (archivo invalido) tambien sigue vacia', () async {
    // La carpeta de bases no es un archivo de SQLite: no se puede abrir.
    final folder = await databaseFactoryFfiNoIsolate.getDatabasesPath();
    final db = SqliteLocalStore(
      factory: databaseFactoryFfiNoIsolate,
      path: folder,
    );

    await db.write('llave', '{}');

    expect(await db.read('llave'), isNull);
  });

  test('en memoria hace lo mismo (pruebas de pantallas)', () async {
    final db = InMemoryLocalStore();
    await db.write('k', 'v');
    await db.enqueue(item('a', 'u1', now));

    expect(await db.read('k'), 'v');
    expect((await db.outbox('u1')).single.id, 'a');
    await db.clear();
    expect(await db.read('k'), isNull);
  });
}
