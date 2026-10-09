import 'package:get/get.dart';

import 'data/datasources/i_community_detail_source.dart';
import 'data/datasources/local/local_community_detail_source.dart';
import 'data/datasources/roble_community_detail_source.dart';
import 'data/repositories/community_detail_repository.dart';
import 'domain/repositories/i_community_detail_repository.dart';
import 'ui/viewmodels/community_detail_controller.dart';

/// Registra la cadena de dependencias del feed de comunidad con GetX.
///
/// [remote] elige entre ROBLE (producción) y la comunidad en memoria (pruebas
/// offline). `main.dart` no pasa nada y usa ROBLE.
void registerCommunityDetail({bool remote = true}) {
  Get.put<ICommunityDetailSource>(
    remote
        ? RobleCommunityDetailSource(Get.find(), Get.find(), Get.find())
        : LocalCommunityDetailSource(),
  );
  Get.put<ICommunityDetailRepository>(CommunityDetailRepository(Get.find()));
  Get.put(CommunityDetailController(Get.find()), permanent: true);
}
