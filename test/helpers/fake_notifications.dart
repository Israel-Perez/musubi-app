import 'dart:async';

import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/features/notifications/data/push_service.dart';
import 'package:musubi_app/features/notifications/domain/notification_models.dart';
import 'package:musubi_app/features/notifications/domain/notification_repository.dart';
import 'package:musubi_app/features/notifications/presentation/notification_providers.dart';

/// Un aviso de prueba.
AppNotification sampleNotification({
  String id = 'n1',
  String type = 'order_created',
  String category = 'orders',
  String title = 'Tienes un pedido nuevo',
  String body = 'Ana pidió 1 × Calculadora Casio. Pedido #MS-1001.',
  NotificationTarget target = NotificationTarget.order,
  String targetId = 'o1',
  bool read = false,
  DateTime? createdAt,
}) => AppNotification(
  id: id,
  type: type,
  category: category,
  title: title,
  body: body,
  target: target,
  targetId: targetId,
  read: read,
  createdAt: createdAt ?? DateTime.utc(2026, 11, 6, 20, 14),
);

/// Centro de notificaciones en memoria: guarda lo que se le pide.
class FakeNotificationRepository implements NotificationRepository {
  new({List<AppNotification>? items}) : items = items ?? [];

  final List<AppNotification> items;
  final List<NotificationTab> listed = [];
  final List<String> read = [];
  final List<String> devices = [];
  int readAll = 0;
  ApiFailure? listFailure;

  @override
  Future<NotificationPage> list(NotificationTab tab, {String? cursor}) async {
    listed.add(tab);
    if (listFailure != null) throw listFailure!;
    final shown = [
      for (final n in items)
        if (tab.category == null || n.category == tab.category) n,
    ];
    return NotificationPage(
      items: shown,
      unread: items.where((n) => !n.read).length,
    );
  }

  @override
  Future<void> markRead(String id) async {
    read.add(id);
    final i = items.indexWhere((n) => n.id == id);
    if (i >= 0) items[i] = items[i].markedRead();
  }

  @override
  Future<void> markAllRead() async {
    readAll++;
    for (var i = 0; i < items.length; i++) {
      items[i] = items[i].markedRead();
    }
  }

  @override
  Future<void> registerDevice(String token) async => devices.add(token);
}

/// Push falso: la prueba decide si hay Firebase y permiso, y empuja avisos.
class FakePushService implements PushService {
  new({this.available = true, this.allowed = false, this.grants = true});

  bool available;
  bool allowed;

  /// Lo que contesta la persona al permiso del sistema.
  bool grants;
  int registers = 0;
  int unregisters = 0;
  int permissionRequests = 0;
  PushOpen? initialOpen;

  final _installations = StreamController<String>.broadcast();
  final _opened = StreamController<PushOpen>.broadcast();
  final _foreground = StreamController<PushOpen>.broadcast();

  /// FCM da (o cambia) el ID de instalacion.
  void installation(String id) => _installations.add(id);

  /// Se toca un push con la app en segundo plano.
  void tap(PushOpen push) => _opened.add(push);

  /// Llega un push con la app abierta.
  void arrive(PushOpen push) => _foreground.add(push);

  @override
  Future<bool> start() async => available;

  @override
  Future<bool> permitted() async => available && allowed;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    allowed = grants;
    return grants;
  }

  @override
  Future<void> register() async {
    registers++;
    installation('fid-telefono');
  }

  @override
  Stream<String> get installations => _installations.stream;

  @override
  Future<void> unregister() async => unregisters++;

  @override
  Future<PushOpen?> initial() async => initialOpen;

  @override
  Stream<PushOpen> get opened => _opened.stream;

  @override
  Stream<PushOpen> get foreground => _foreground.stream;
}

/// Si ya se pregunto por el permiso, en memoria.
class FakePushAskStore implements PushAskStore {
  new({this.wasAsked = false});

  bool wasAsked;

  @override
  Future<bool> asked() async => wasAsked;

  @override
  Future<void> markAsked() async => wasAsked = true;
}
