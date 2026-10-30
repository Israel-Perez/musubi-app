import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musubi_app/core/network/api_client.dart';
import 'package:musubi_app/features/auth/data/http_account_repository.dart';
import 'package:musubi_app/features/auth/data/http_auth_repository.dart';
import 'package:musubi_app/features/auth/domain/account_repository.dart';
import 'package:musubi_app/features/auth/domain/auth_repository.dart';

/// Repositorio de registro y verificacion (en pruebas, un fake).
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => HttpAuthRepository(ref.watch(publicDioProvider)),
);

/// La cuenta de quien tiene sesion (HU-46); en pruebas, un fake.
final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => HttpAccountRepository(ref.watch(dioProvider)),
);

/// Reloj de las pantallas (cuenta regresiva de "Reenviar codigo"); en
/// pruebas se fija.
final clockProvider = Provider<DateTime Function()>(
  (ref) =>
      () => DateTime.now().toUtc(),
);
