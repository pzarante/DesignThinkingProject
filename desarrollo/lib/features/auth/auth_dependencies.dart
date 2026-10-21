import 'package:get/get.dart';
import 'package:roble/roble.dart';

import '../../core/i_local_preferences.dart';
import '../../core/roble_cache.dart';
import 'data/datasources/remote/authentication_source_service.dart';
import 'data/datasources/remote/i_authentication_source.dart';
import 'data/datasources/remote/roble_authentication_source.dart';
import 'data/repositories/auth_repository.dart';
import 'domain/repositories/i_auth_repository.dart';
import 'ui/viewmodels/authentication_controller.dart';

/// Registers the authentication dependency chain with GetX.
///
/// Authentication is needed as soon as the application starts (the home feed
/// already asks whether there is an account), so the source, repository, and
/// controller are created eagerly.
///
/// [remote] en false usa [AuthenticationSourceService], que guarda las cuentas
/// en las preferencias locales: así las pruebas no crean usuarios en ROBLE.
void registerAuth({bool remote = true}) {
  Get.put<IAuthenticationSource>(
    remote
        ? RobleAuthenticationSource(
            Get.find<RobleApiDataBase>(),
            Get.find<RobleTableCache>(),
          )
        : AuthenticationSourceService(Get.find<ILocalPreferences>()),
    permanent: true,
  );
  Get.put<IAuthRepository>(AuthRepository(Get.find()));
  Get.put(AuthenticationController(Get.find()));
}
