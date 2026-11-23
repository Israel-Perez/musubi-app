import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Un evento para el calendario del telefono (HU-62: la entrega de un pedido).
class CalendarEvent {
  const new({
    required this.title,
    required this.start,
    required this.end,
    required this.location,
    required this.description,
  });

  final String title;
  final DateTime start;
  final DateTime end;
  final String location;
  final String description;
}

/// "Agregar al calendario" (HU-62). En Android abre la app de calendario con
/// el evento ya lleno (`Intent.ACTION_INSERT` de `CalendarContract`, en
/// `MainActivity.kt`): la persona lo guarda ahi. Sin permiso de calendario y
/// sin leer nada del telefono.
abstract interface class DeviceCalendar {
  /// `false` si no hay una app de calendario que lo abra.
  Future<bool> add(CalendarEvent event);
}

class PlatformDeviceCalendar implements DeviceCalendar {
  const new();

  static const _channel = MethodChannel('musubi/calendar');

  @override
  Future<bool> add(CalendarEvent event) async {
    try {
      return await _channel.invokeMethod<bool>('addEvent', {
            'title': event.title,
            'begin': event.start.millisecondsSinceEpoch,
            'end': event.end.millisecondsSinceEpoch,
            'location': event.location,
            'description': event.description,
          }) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}

/// En pruebas, un fake.
final deviceCalendarProvider = Provider<DeviceCalendar>(
  (ref) => const PlatformDeviceCalendar(),
);
