import 'package:get/get.dart';
import 'package:loggy/loggy.dart';

import '../../domain/models/user_profile.dart';
import '../../domain/repositories/i_profile_repository.dart';

/// Búsqueda de personas por `user_name` para la pestaña "Personas" de
/// Explorar.
///
/// La lista se trae una vez y se filtra en memoria, igual que hace
/// `HomeController` con los proyectos: ROBLE solo admite filtros de igualdad,
/// así que una búsqueda por coincidencia parcial tendría que traerse la tabla
/// entera en cada tecla.
class UserSearchController extends GetxController with UiLoggy {
  UserSearchController(this._repository);

  final IProfileRepository _repository;

  final RxList<UserSummary> users = <UserSummary>[].obs;
  final RxString query = ''.obs;
  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString();

  @override
  void onInit() {
    load();
    super.onInit();
  }

  Future<void> load() async {
    loggy.debug('UserSearchController: loading users');
    isLoading.value = true;
    errorMessage.value = null;
    try {
      users.assignAll(await _repository.getUsers());
    } catch (exception, stackTrace) {
      loggy.error('UserSearchController: error loading users', exception, stackTrace);
      errorMessage.value = 'No se pudieron cargar las personas.';
    } finally {
      isLoading.value = false;
    }
  }

  void setQuery(String value) => query.value = value;

  /// Coincidencias del texto buscado, primero por `user_name` y después por
  /// nombre real: quien escribe "ana" espera ver a `anamartinez` antes que a
  /// alguien que se llama Ana de segundo nombre.
  List<UserSummary> get results {
    final needle = query.value.trim().toLowerCase();
    if (needle.isEmpty) return users.toList();

    final byUserName = <UserSummary>[];
    final byFullName = <UserSummary>[];
    for (final user in users) {
      if (user.userName.toLowerCase().contains(needle)) {
        byUserName.add(user);
      } else if ((user.fullName ?? '').toLowerCase().contains(needle)) {
        byFullName.add(user);
      }
    }
    // Dentro del grupo del `user_name`, los que empiezan por lo buscado van
    // primero; es lo que se espera al escribir las primeras letras.
    byUserName.sort((a, b) {
      final aStarts = a.userName.toLowerCase().startsWith(needle);
      final bStarts = b.userName.toLowerCase().startsWith(needle);
      if (aStarts != bStarts) return aStarts ? -1 : 1;
      return a.userName.toLowerCase().compareTo(b.userName.toLowerCase());
    });
    return [...byUserName, ...byFullName];
  }
}
