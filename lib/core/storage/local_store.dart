import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Un mensaje escrito sin conexion que espera la red ("Por enviar", HU-63).
@immutable
class OutboxItem {
  const new({
    required this.id,
    required this.userId,
    required this.conversationId,
    required this.text,
    required this.createdAt,
  });

  /// Id local (`local-…`): la burbuja lo usa hasta que la API da el suyo.
  final String id;

  /// De quien es (otra cuenta en el mismo telefono nunca lo envia).
  final String userId;
  final String conversationId;
  final String text;

  /// Cuando se escribio (UTC).
  final DateTime createdAt;
}

/// Lo que la app guarda en el telefono (HU-63, L-16h): las respuestas de las
/// pantallas que se abren sin conexion y los mensajes por enviar. Nada de
/// sesion: los tokens siguen en el almacen seguro (02-01).
abstract interface class LocalStore {
  /// La respuesta guardada para esa llave, o `null`.
  Future<String?> read(String key);

  /// Guarda (o reemplaza) la respuesta de una llave.
  Future<void> write(String key, String body);

  /// Los mensajes por enviar de esa persona, del mas viejo al mas nuevo.
  Future<List<OutboxItem>> outbox(String userId);

  Future<void> enqueue(OutboxItem item);

  Future<void> dequeue(String id);

  /// Borra todo (cerrar sesion o eliminar la cuenta, MASVS-STORAGE).
  Future<void> clear();
}

/// En memoria (pruebas y respaldo si SQLite no abre).
class InMemoryLocalStore implements LocalStore {
  final Map<String, String> responses = {};
  final List<OutboxItem> items = [];

  @override
  Future<String?> read(String key) async => responses[key];

  @override
  Future<void> write(String key, String body) async => responses[key] = body;

  @override
  Future<List<OutboxItem>> outbox(String userId) async => [
    for (final item in items)
      if (item.userId == userId) item,
  ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  @override
  Future<void> enqueue(OutboxItem item) async => items
    ..removeWhere((i) => i.id == item.id)
    ..add(item);

  @override
  Future<void> dequeue(String id) async => items.removeWhere((i) => i.id == id);

  @override
  Future<void> clear() async {
    responses.clear();
    items.clear();
  }
}

/// SQLite con `sqflite` (archivo privado de la app; `allowBackup=false`).
///
/// Si la base no abre (una prueba sin el plugin, un disco lleno), cada
/// operacion se comporta como vacia: la app sigue, solo sin lo guardado.
class SqliteLocalStore implements LocalStore {
  new({this._factory, this._path, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// Nombre del archivo en la carpeta de bases de la app.
  static const fileName = 'musubi_local.db';

  /// Las respuestas viejas se borran al abrir (no se muestra algo de hace un
  /// mes como "lo ultimo que cargaste").
  static const responseRetention = Duration(days: 30);

  /// Un mensaje que no salio en una semana ya no se envia.
  static const outboxRetention = Duration(days: 7);

  /// Las pruebas en la VM usan el motor real de SQLite (`sqflite_common_ffi`,
  /// en `test/flutter_test_config.dart`): ahi no hay plugin de Android.
  @visibleForTesting
  static DatabaseFactory? testFactory;

  /// La base de [testFactory] (en memoria: una nueva por cada almacen).
  @visibleForTesting
  static String? testPath;

  final DatabaseFactory? _factory;
  final String? _path;
  final DateTime Function() _clock;
  Future<Database?>? _db;

  Future<Database?> _open() => _db ??= _openOnce();

  Future<Database?> _openOnce() async {
    try {
      // El del plugin, no el global (sin plugin: MissingPluginException).
      final factory = _factory ?? testFactory ?? databaseFactorySqflitePlugin;
      final path =
          _path ??
          (testFactory != null && _factory == null ? testPath : null) ??
          p.join(await factory.getDatabasesPath(), fileName);
      final db = await factory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, _) async {
            await db.execute(
              'CREATE TABLE responses (key TEXT PRIMARY KEY, '
              'body TEXT NOT NULL, saved_at INTEGER NOT NULL)',
            );
            await db.execute(
              'CREATE TABLE outbox (id TEXT PRIMARY KEY, '
              'user_id TEXT NOT NULL, conversation_id TEXT NOT NULL, '
              'text TEXT NOT NULL, created_at INTEGER NOT NULL)',
            );
          },
        ),
      );
      final now = _clock().toUtc();
      await db.delete(
        'responses',
        where: 'saved_at < ?',
        whereArgs: [now.subtract(responseRetention).millisecondsSinceEpoch],
      );
      await db.delete(
        'outbox',
        where: 'created_at < ?',
        whereArgs: [now.subtract(outboxRetention).millisecondsSinceEpoch],
      );
      return db;
    } on DatabaseException {
      // Base danada o disco lleno: la app sigue sin lo guardado.
      return null;
    } on MissingPluginException {
      // Sin el plugin (pruebas de widget): la app sigue sin lo guardado.
      return null;
    }
  }

  @override
  Future<String?> read(String key) async {
    final rows = await (await _open())?.query(
      'responses',
      columns: ['body'],
      where: 'key = ?',
      whereArgs: [key],
    );
    return rows == null || rows.isEmpty ? null : rows.first['body'] as String?;
  }

  @override
  Future<void> write(String key, String body) async {
    await (await _open())?.insert('responses', {
      'key': key,
      'body': body,
      'saved_at': _clock().toUtc().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<List<OutboxItem>> outbox(String userId) async {
    final rows = await (await _open())?.query(
      'outbox',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at',
    );
    return [
      for (final row in rows ?? const <Map<String, Object?>>[])
        OutboxItem(
          id: row['id']! as String,
          userId: row['user_id']! as String,
          conversationId: row['conversation_id']! as String,
          text: row['text']! as String,
          createdAt: DateTime.fromMillisecondsSinceEpoch(
            row['created_at']! as int,
            isUtc: true,
          ),
        ),
    ];
  }

  @override
  Future<void> enqueue(OutboxItem item) async {
    await (await _open())?.insert('outbox', {
      'id': item.id,
      'user_id': item.userId,
      'conversation_id': item.conversationId,
      'text': item.text,
      'created_at': item.createdAt.toUtc().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> dequeue(String id) async {
    await (await _open())?.delete('outbox', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> clear() async {
    final db = await _open();
    await db?.delete('responses');
    await db?.delete('outbox');
  }
}

/// La base local del telefono. En pruebas, [InMemoryLocalStore].
final localStoreProvider = Provider<LocalStore>((ref) => SqliteLocalStore());
