import 'package:get/get.dart';

import 'data/datasources/i_home_source.dart';
import 'data/datasources/local/local_home_source.dart';
import 'data/datasources/roble_home_source.dart';
import 'data/repositories/home_repository.dart';
import 'domain/repositories/i_home_repository.dart';
import 'ui/viewmodels/home_controller.dart';

/// Registers the home dependency chain with GetX.
///
/// [remote] elige entre ROBLE (producción) y el catálogo en memoria (pruebas
/// offline, sin sesión ni red real). `main.dart` no pasa nada y usa ROBLE.
void registerHome({bool remote = true}) {
  final IHomeSource source = remote
      ? RobleHomeSource(Get.find(), Get.find())
      : LocalHomeSource();
  Get.put<IHomeSource>(source);
  Get.put<IHomeRepository>(HomeRepository(Get.find()));
  Get.put(HomeController(Get.find()), permanent: true);
}
