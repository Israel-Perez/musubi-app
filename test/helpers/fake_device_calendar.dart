import 'package:musubi_app/core/platform/device_calendar.dart';

/// Fake de [DeviceCalendar] (HU-62): guarda los eventos y puede no tener app.
class FakeDeviceCalendar implements DeviceCalendar {
  new({this.result = true});

  bool result;
  final List<CalendarEvent> events = [];

  @override
  Future<bool> add(CalendarEvent event) async {
    events.add(event);
    return result;
  }
}
