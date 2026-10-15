import 'package:flutter/foundation.dart';

/// Estado de la conexion con musubi-api.
@immutable
sealed class ApiStatus {
  const new();
}

/// La API respondio el ping con su version.
final class ApiOnline extends ApiStatus {
  const new({required this.version});

  final String version;

  @override
  bool operator ==(Object other) =>
      other is ApiOnline && other.version == version;

  @override
  int get hashCode => version.hashCode;
}

/// La API no respondio o respondio algo inesperado; [message] es apto para
/// mostrarse al usuario (RNF-18).
final class ApiOffline extends ApiStatus {
  const new({required this.message});

  final String message;

  @override
  bool operator ==(Object other) =>
      other is ApiOffline && other.message == message;

  @override
  int get hashCode => message.hashCode;
}
