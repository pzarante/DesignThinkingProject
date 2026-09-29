import 'package:get/get.dart';

import '../home/domain/repositories/i_home_repository.dart';
import 'ui/viewmodels/community_settings_controller.dart';

/// Registra el controlador de configuración de comunidad con el repositorio
/// ya usado por el feed principal.
void registerCommunitySettings() {
  Get.put<CommunitySettingsController>(
    CommunitySettingsController(Get.find<IHomeRepository>()),
    permanent: true,
  );
}
