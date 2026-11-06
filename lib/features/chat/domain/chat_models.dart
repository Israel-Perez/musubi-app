import 'package:flutter/foundation.dart';
import 'package:musubi_app/core/session/session_tokens.dart';

// Modelos del chat (HU-20, HU-22). Forma canonica: filas "M-07" de
// musubi-api `docs/endpoints.md`; aqui solo lo que muestra la app.

/// Papel de quien mira la conversacion.
enum ChatRole {
  /// Inicio la conversacion para comprar ("Compra").
  buyer,

  /// Dueno de la publicacion ("Venta").
  seller;

  /// Valor de la API (`buyer` / `seller`).
  static ChatRole parse(Object? value) =>
      value == 'seller' ? ChatRole.seller : ChatRole.buyer;
}

/// La otra persona de la conversacion.
@immutable
class ChatCounterpart {
  const new({required this.id, required this.name});

  final String id;
  final String name;

  /// "Valeria Cruz" → "VC" (como la maqueta).
  String get initials => initialsOf(name);

  /// Nombre de pila ("Valeria").
  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  /// Pareja de colores estable para su avatar (0..4).
  int get palette => id.codeUnits.fold(0, (sum, unit) => sum + unit) % 5;
}

/// Tarjeta de la publicacion de la que se habla (maqueta `Chat-Valeria`).
/// Precio, estado y foto son los de ahora; si la publicacion ya no se puede
/// ver, [available] es `false` y solo queda el nombre guardado.
@immutable
class ChatContext {
  const new({
    required this.id,
    required this.title,
    required this.available,
    this.priceCents,
    this.condition,
    this.conditionDetail,
    this.photoUrl,
  });

  final String id;
  final String title;
  final bool available;
  final int? priceCents;

  /// `new` o `used`.
  final String? condition;

  /// `likeNew`, `good` o `fair`.
  final String? conditionDetail;
  final String? photoUrl;

  /// "Usado · con detalles" (maqueta) o "Nuevo".
  String? get conditionLabel => switch ((condition, conditionDetail)) {
    ('new', _) => 'Nuevo',
    ('used', 'likeNew') => 'Usado · como nuevo',
    ('used', 'good') => 'Usado · buen estado',
    ('used', 'fair') => 'Usado · con detalles',
    ('used', _) => 'Usado',
    _ => null,
  };
}

/// Una conversacion abierta.
@immutable
class Conversation {
  const new({
    required this.id,
    required this.role,
    required this.counterpart,
    required this.context,
  });

  final String id;
  final ChatRole role;
  final ChatCounterpart counterpart;
  final ChatContext context;
}

/// Un mensaje de texto. Tambien es lo que llega por el hub (`messageCreated`).
@immutable
class ChatMessage {
  const new({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.sentAt,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final DateTime sentAt;

  @override
  bool operator ==(Object other) => other is ChatMessage && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Pagina de mensajes, del mas nuevo al mas viejo.
@immutable
class MessagePage {
  const new({required this.items, this.nextCursor});

  final List<ChatMessage> items;

  /// Cursor de los anteriores, o `null` si no hay mas.
  final String? nextCursor;
}

/// Una fila de la bandeja (maqueta `Mensajes`).
@immutable
class InboxEntry {
  const new({
    required this.id,
    required this.role,
    required this.counterpart,
    required this.contextTitle,
    required this.lastSenderId,
    required this.lastText,
    required this.lastAt,
    required this.unread,
    this.contextPhotoUrl,
  });

  final String id;
  final ChatRole role;
  final ChatCounterpart counterpart;
  final String contextTitle;
  final String? contextPhotoUrl;
  final String lastSenderId;
  final String lastText;
  final DateTime lastAt;
  final int unread;

  /// "Compra · Casio fx-991ES Plus" / "Venta · Calculo, Stewart".
  String get contextLine =>
      '${role == ChatRole.buyer ? 'Compra' : 'Venta'} · $contextTitle';
}

/// Pagina de la bandeja.
@immutable
class InboxPage {
  const new({required this.items, this.nextCursor});

  final List<InboxEntry> items;
  final String? nextCursor;
}

/// Pestanas de la bandeja (maqueta `Mensajes`).
enum InboxFilter {
  all('Todos', null),
  purchases('Compras', 'buyer'),
  sales('Ventas', 'seller');

  new(this.label, this.role);

  final String label;

  /// Valor de `?role=` (o ninguno).
  final String? role;
}
