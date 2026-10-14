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
      loggy.error(
        'CommunityDetailController: load failed',
        exception,
        stackTrace,
      );
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
  Future<void> toggleFollowing() async {
    final current = community.value;
    if (current == null || _toggling) return;
    // Un segundo toque antes de que termine el primero crearía la fila dos veces.
    _toggling = true;

    final wasFollowing = current.isFollowing;
    community.value = current.copyWith(
      isFollowing: !wasFollowing,
      followerCount: current.followerCount + (wasFollowing ? -1 : 1),
    );
    actionError.value = '';
    try {
      final isFollowing = await _repository.toggleFollowing(current.id);
      // Lo que cambió de verdad respecto de antes de pulsar: quien creó la
      // comunidad no puede dejarla y el servidor responde que sigue, así que
      // el contador no se mueve.
      community.value = current.copyWith(
        isFollowing: isFollowing,
        followerCount:
            current.followerCount +
            (isFollowing ? 1 : 0) -
            (wasFollowing ? 1 : 0),
      );
      if (Get.isRegistered<HomeController>()) {
        await Get.find<HomeController>().getFeed();
      }
    } catch (exception) {
      loggy.error('CommunityDetailController: toggle failed', exception);
      community.value = current;
      actionError.value = errors.errorMessage(exception);
    } finally {
      _toggling = false;
    }
  }

  bool _toggling = false;
}
