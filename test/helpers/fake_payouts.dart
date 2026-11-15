import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/features/orders/domain/payment_models.dart';

/// Los bancos de las pruebas (los primeros de la lista de la API).
const sampleBanks = [
  PayoutBank(code: '002', name: 'Banamex'),
  PayoutBank(code: '012', name: 'BBVA México'),
  PayoutBank(code: '014', name: 'Santander'),
  PayoutBank(code: '638', name: 'Nu México'),
];

/// La cuenta de Ana (maqueta `Cuenta-pagos`).
const sampleAccount = PayoutAccount(
  holderName: 'Ana Sofía Ramírez',
  bankCode: '012',
  bankName: 'BBVA México',
  clabeLast4: '4829',
);

/// Cuenta para recibir pagos en memoria (HU-55).
class FakePayoutRepository implements PayoutRepository {
  new({this.account, this.available = true});

  PayoutAccount? account;
  bool available;

  /// Falla el siguiente "Guardar cuenta".
  ApiFailure? saveFailure;

  final List<(String, String)> saved = [];
  int removed = 0;

  @override
  Future<List<PayoutBank>> banks() async => sampleBanks;

  @override
  Future<PayoutStatus> mine() async =>
      PayoutStatus(available: available, account: account);

  @override
  Future<PayoutAccount> save({
    required String holderName,
    required String clabe,
  }) async {
    saved.add((holderName, clabe));
    final failure = saveFailure;
    if (failure != null) {
      saveFailure = null;
      throw failure;
    }
    final digits = Clabe.digits(clabe);
    final bank = sampleBanks.firstWhere(
      (b) => digits.startsWith(b.code),
      orElse: () => const PayoutBank(code: '000', name: 'Otro banco'),
    );
    return account = PayoutAccount(
      holderName: holderName,
      bankCode: bank.code,
      bankName: bank.name,
      clabeLast4: digits.substring(digits.length - 4),
    );
  }

  @override
  Future<void> remove() async {
    removed++;
    account = null;
  }
}
