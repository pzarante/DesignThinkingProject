import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loggy/loggy.dart';
import 'package:roble/roble.dart';

import 'app_routes.dart';
import 'core/app_theme.dart';
import 'core/i_local_preferences.dart';
import 'core/local_preferences_secured.dart';
import 'core/local_preferences_shared.dart';
import 'core/roble_cache.dart';
import 'core/roble_config.dart';

import 'features/auth/auth_dependencies.dart';
import 'features/community_creation/community_creation_dependencies.dart';
import 'features/community_detail/community_detail_dependencies.dart';
import 'features/community_settings/community_settings_dependencies.dart';
import 'features/home/home_dependencies.dart';
import 'features/notifications/notifications_dependencies.dart';
import 'features/product/product_dependencies.dart';
import 'features/profile/profile_dependencies.dart';
import 'features/project_creation/project_creation_dependencies.dart';
import 'features/project_detail/project_detail_dependencies.dart';
import 'features/project_applications/project_applications_dependencies.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Loggy.initLoggy(logPrinter: const PrettyPrinter(showColors: true));

  registerDependencies(
    preferences: kIsWeb ? LocalPreferencesShared() : LocalPreferencesSecured(),
  );
  runApp(const MyApp());
}

/// Registra todo lo que la app necesita para arrancar.
///
/// [remote] en false cambia ROBLE por las fuentes en memoria de cada feature:
/// es como corren las pruebas de integración, sin red ni cuentas reales.
void registerDependencies({
  required ILocalPreferences preferences,
  bool remote = true,
}) {
  Get.put<ILocalPreferences>(preferences, permanent: true);

  if (remote) {
    // Un solo cliente para toda la app: crearlo de nuevo en cada pantalla le
    // daría a cada copia su propia sesión.
    final robleDb = RobleApiDataBase(
      config: RobleApiConfig.fromContract(
        baseUrl: RobleConfig.baseUrl,
        contractId: RobleConfig.contractId,
      ),
    );
    Get.put<RobleApiDataBase>(robleDb, permanent: true);
    // Memoria corta compartida: sin ella cada pantalla vuelve a pedir las
    // mismas tablas (`users`, `tags`, `project_stages`) una y otra vez.
    Get.put<RobleTableCache>(RobleTableCache(robleDb), permanent: true);
  }

  registerAuth(remote: remote);
  registerNotifications(remote: remote);
  registerProfile(remote: remote);
  registerHome(remote: remote);
  registerProjectDetail(remote: remote);
  registerProjectCreation(remote: remote);
  registerCommunityCreation();
  registerCommunitySettings();
  registerCommunityDetail(remote: remote);
  registerProjectApplications(remote: remote);
  registerProduct();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Clean template',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode
          .light, // fuerza claro, ignora el modo del sistema (esto solo es para que se parezca más al figma)
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.home,
      getPages: AppRoutes.pages,
    );
  }
}
