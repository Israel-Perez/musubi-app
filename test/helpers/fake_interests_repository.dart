import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/features/profile/domain/interests_repository.dart';

class FakeInterestsRepository implements InterestsRepository {
  new({List<String>? saved}) : saved = saved ?? [];

  List<String> saved;
  bool failLoad = false;
  bool failSave = false;
  int loads = 0;
  final saves = <List<String>>[];

  @override
  Future<List<String>> get() async {
    loads++;
    if (failLoad) throw _offline;
    return [...saved];
  }

  @override
  Future<List<String>> save(List<String> categories) async {
    saves.add([...categories]);
    if (failSave) throw _offline;
    return saved = [...categories];
  }

  static const _offline = ApiFailure(
    code: ApiFailure.networkOffline,
    message: 'No hay conexión. Revisa tu internet e inténtalo de nuevo.',
  );
}
