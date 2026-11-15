import 'package:flutter/foundation.dart';

/// "Paga por transferencia" (`Pago-transferencia`, HU-55): la cuenta de quien
/// vende. [clabe] viene completa para quien compra ("012 180 0154 2378 9134")
/// y enmascarada para quien vende ("•••• 9134").
@immutable
class TransferDetails {
  const new({
    required this.amountCents,
    required this.bankName,
    required this.holderName,
    required this.clabe,
    required this.clabeLast4,
    required this.concept,
    this.reference,
    this.reportedAt,
    this.notReceivedAt,
    this.validatedAt,
  });

  final int amountCents;
  final String bankName;
  final String holderName;
  final String clabe;
  final String clabeLast4;

  /// "Concepto · escríbelo tal cual": el numero del pedido (`MS-2481`).
  final String concept;
  final String? reference;
  final DateTime? reportedAt;
  final DateTime? notReceivedAt;
  final DateTime? validatedAt;

  /// La CLABE sin espacios, para copiarla.
  String get clabeDigits => clabe.replaceAll(' ', '');
}

/// Un banco de la CLABE (clave de 3 digitos de SPEI).
@immutable
class PayoutBank {
  const new({required this.code, required this.name});

  final String code;
  final String name;
}

/// Mi cuenta para recibir pagos, enmascarada (`Cuenta-pagos`).
@immutable
class PayoutAccount {
  const new({
    required this.holderName,
    required this.bankCode,
    required this.bankName,
    required this.clabeLast4,
  });

  final String holderName;
  final String bankCode;
  final String bankName;
  final String clabeLast4;

  /// "BBVA ···· 4821" (la fila de `Ajustes`).
  String get short => '${bankName.split(' ').first} ···· $clabeLast4';
}

/// Mi cuenta y si se pueden guardar cuentas (sin llave en la API, no: RNF-15).
@immutable
class PayoutStatus {
  const new({this.available = true, this.account});

  final bool available;
  final PayoutAccount? account;
}

/// La CLABE (HU-55): 18 digitos con su digito verificador (pesos 3, 7 y 1 de
/// Banxico). La API vuelve a validarla; aqui solo es para avisar mientras se
/// escribe.
abstract final class Clabe {
  static const length = 18;

  /// Solo los digitos.
  static String digits(String value) => value.replaceAll(RegExp(r'\D'), '');

  /// "012 180 0154 8821 4821" (grupos de 3, 3, 4, 4 y 4, como la maqueta).
  static String format(String value) {
    final d = digits(value);
    final groups = [3, 3, 4, 4, 4];
    final out = <String>[];
    var i = 0;
    for (final size in groups) {
      if (i >= d.length) break;
      final end = i + size > d.length ? d.length : i + size;
      out.add(d.substring(i, end));
      i = end;
    }
    return out.join(' ');
  }

  /// Si son 18 digitos con su digito verificador.
  static bool isValid(String value) {
    final d = digits(value);
    if (d.length != length) return false;
    const weights = [3, 7, 1];
    var sum = 0;
    for (var i = 0; i < 17; i++) {
      sum += (int.parse(d[i]) * weights[i % 3]) % 10;
    }
    return (10 - sum % 10) % 10 == int.parse(d[17]);
  }
}

/// La cuenta para recibir pagos (`/payouts/*`, spec `musubi-api:HU-55`).
abstract interface class PayoutRepository {
  /// Los bancos de la CLABE.
  Future<List<PayoutBank>> banks();

  /// Mi cuenta (enmascarada).
  Future<PayoutStatus> mine();

  /// "Guardar cuenta": reemplaza la anterior.
  Future<PayoutAccount> save({
    required String holderName,
    required String clabe,
  });

  /// "Quitar cuenta".
  Future<void> remove();
}
