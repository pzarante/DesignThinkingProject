import 'package:get/get.dart';

import 'data/datasources/i_community_creation_source.dart';
import 'data/datasources/local/local_community_creation_source.dart';
import 'data/repositories/community_creation_repository.dart';
import 'domain/repositories/i_community_creation_repository.dart';
import 'ui/viewmodels/community_creation_controller.dart';

/// Registers the community-creation dependency chain with GetX.
void registerCommunityCreation() {
  Get.put<ICommunityCreationSource>(LocalCommunityCreationSource());
  Get.put<ICommunityCreationRepository>(
    CommunityCreationRepository(Get.find()),
  );
  Get.put(
    CommunityCreationController(Get.find(), Get.find()),
    permanent: true,
  );
}
