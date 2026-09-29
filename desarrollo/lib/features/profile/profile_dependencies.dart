import 'package:get/get.dart';

import 'data/datasources/i_profile_source.dart';
import 'data/datasources/local/local_profile_source.dart';
import 'data/datasources/roble_profile_source.dart';
import 'data/repositories/profile_repository.dart';
import 'domain/repositories/i_profile_repository.dart';
import 'ui/viewmodels/profile_controller.dart';
import 'ui/viewmodels/user_search_controller.dart';

/// Registra la cadena de dependencias del perfil con GetX.
///
/// [remote] elige entre ROBLE (producción) y los perfiles en memoria (pruebas
/// offline, sin sesión ni red real). `main.dart` no pasa nada y usa ROBLE.
///
/// Necesita que `registerAuth()` ya haya corrido: el controlador pregunta al
/// repositorio de autenticación quién tiene la sesión.
void registerProfile({bool remote = true}) {
  Get.put<IProfileSource>(
    remote ? RobleProfileSource(Get.find()) : LocalProfileSource(),
  );
  Get.put<IProfileRepository>(ProfileRepository(Get.find()));
  Get.put(ProfileController(Get.find(), Get.find()), permanent: true);
  Get.put(UserSearchController(Get.find()), permanent: true);
}
