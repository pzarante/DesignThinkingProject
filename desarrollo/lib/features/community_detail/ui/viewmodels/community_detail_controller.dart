import 'package:get/get.dart';
import 'package:loggy/loggy.dart';

import '../../../../core/error_message.dart' as errors;
import '../../../home/ui/viewmodels/home_controller.dart';
import '../../domain/models/community_detail.dart';
import '../../domain/repositories/i_community_detail_repository.dart';

/// Estado del feed de una comunidad.
class CommunityDetailController extends GetxController with UiLoggy {
  CommunityDetailController(this._repository);

  final ICommunityDetailRepository _repository;

  final Rxn<CommunityDetail> community = Rxn<CommunityDetail>();
  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString();

  /// Mensaje del último intento de seguir que no se pudo hacer; la pantalla
  /// lo enseña y lo vacía.
  final RxString actionError = ''.obs;

  Future<void> load(String communityId) async {
    loggy.debug('CommunityDetailController: loading $communityId');
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final loaded = await _repository.getDetail(communityId);
      community.value = loaded;
      if (loaded == null) {
        errorMessage.value = 'Esta comunidad ya no está disponible.';
      }
    } catch (exception, stackTrace) {
      loggy.error('CommunityDetailController: load failed', exception, stackTrace);
      community.value = null;
      errorMessage.value = errors.errorMessage(exception);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshCommunity() async {
    final id = community.value?.id;
    if (id != null) await load(id);
  }

  /// Sigue o deja de seguir, de forma optimista y con reversa si falla.
  ///
  /// Al terminar recarga el feed de inicio: "Comunidades que sigues" sale de
  /// la misma tabla que se acaba de tocar.
  Future<void> toggleMembership() async {
    final current = community.value;
    if (current == null) return;

    final wasMember = current.isMember;
    community.value = current.copyWith(
      isMember: !wasMember,
      memberCount: current.memberCount + (wasMember ? -1 : 1),
    );
    actionError.value = '';
    try {
      final isMember = await _repository.toggleMembership(current.id);
      community.value = current.copyWith(
        isMember: isMember,
        memberCount: current.memberCount + (isMember ? 1 : -1),
      );
      if (Get.isRegistered<HomeController>()) {
        await Get.find<HomeController>().getFeed();
      }
    } catch (exception) {
      loggy.error('CommunityDetailController: toggle failed', exception);
      community.value = current;
      actionError.value = errors.errorMessage(exception);
    }
  }
}
