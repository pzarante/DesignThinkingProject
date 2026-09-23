import 'package:get/get.dart';
import 'package:roble/roble.dart';

import 'data/datasources/remote/i_authentication_source.dart';
import 'data/datasources/remote/roble_authentication_source.dart';
import 'data/repositories/auth_repository.dart';
import 'domain/repositories/i_auth_repository.dart';
import 'ui/viewmodels/authentication_controller.dart';

/// Registers the authentication dependency chain with GetX.
///
/// Authentication is needed by [Central] as soon as the application starts, so
/// the source, repository, and controller are created eagerly.
void registerAuth() {
  Get.put<IAuthenticationSource>(
    RobleAuthenticationSource(Get.find<RobleApiDataBase>()),
    permanent: true,
  );
  Get.put<IAuthRepository>(AuthRepository(Get.find()));
  Get.put(AuthenticationController(Get.find()));
}
