import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musubi_app/core/network/api_client.dart';
import 'package:musubi_app/features/profile/data/http_interests_repository.dart';
import 'package:musubi_app/features/profile/domain/interests_repository.dart';

final interestsRepositoryProvider = Provider<InterestsRepository>(
  (ref) => HttpInterestsRepository(ref.watch(dioProvider)),
);

/// Mis intereses (HU-66), para la fila de `Ajustes` y la pantalla. Sin el
/// reintento automático: la pantalla ofrece reintentar.
final FutureProvider<List<String>> myInterestsProvider =
    FutureProvider.autoDispose<List<String>>(
      (ref) => ref.watch(interestsRepositoryProvider).get(),
      retry: (_, _) => null,
    );
