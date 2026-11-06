// Fechas y horas del chat como las escribe la maqueta (es-MX): "6:40 p. m.",
// "Ayer, 6:40 p. m.", "lun" y "28/10".

const _weekdays = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];

/// "6:40 p. m." (12 horas, como `Chat-Valeria`).
String clockTime(DateTime local) {
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${local.hour < 12 ? 'a. m.' : 'p. m.'}';
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// Hora debajo de un grupo de mensajes: "6:40 p. m.", "Ayer, 6:40 p. m." o
/// "28/10, 6:40 p. m.". Recibe horas locales.
String messageStamp(DateTime local, DateTime nowLocal) {
  final time = clockTime(local);
  if (_sameDay(local, nowLocal)) return time;
  if (_sameDay(local, nowLocal.subtract(const Duration(days: 1)))) {
    return 'Ayer, $time';
  }
  return '${_shortDate(local)}, $time';
}

/// Hora de una fila de `Mensajes`: "8:31 p. m.", "Ayer", "lun" o "28/10".
String inboxStamp(DateTime local, DateTime nowLocal) {
  if (_sameDay(local, nowLocal)) return clockTime(local);
  final days = _day(nowLocal).difference(_day(local)).inDays;
  if (days == 1) return 'Ayer';
  if (days > 1 && days < 7) return _weekdays[local.weekday - 1];
  return _shortDate(local);
}

/// Dia del aviso de inicio: "Hoy", "Ayer" o "28/10".
String dayLabel(DateTime local, DateTime nowLocal) {
  if (_sameDay(local, nowLocal)) return 'Hoy';
  if (_sameDay(local, nowLocal.subtract(const Duration(days: 1)))) {
    return 'Ayer';
  }
  return _shortDate(local);
}

String _shortDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
