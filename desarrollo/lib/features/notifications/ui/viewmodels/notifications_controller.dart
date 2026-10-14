import 'package:get/get.dart';
import 'package:loggy/loggy.dart';

import '../../../auth/ui/viewmodels/authentication_controller.dart';
import '../../domain/models/app_notification.dart';
import '../../domain/repositories/i_notification_repository.dart';

class NotificationsController extends GetxController with UiLoggy {
  NotificationsController(this.repository);

  final INotificationRepository repository;

  final RxList<AppNotification> items = <AppNotification>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    refresh();
    // La bandeja es de quien tiene sesión: al entrar o salir, otra.
    if (Get.isRegistered<AuthenticationController>()) {
      ever(Get.find<AuthenticationController>().loggedUser, (_) => refresh());
    }
  }

  @override
  Future<void> refresh() async {
    isLoading.value = true;
    try {
      items.value = await repository.getAll();
      unreadCount.value = items.where((n) => !n.isRead).length;
    } catch (exception) {
      loggy.error('NotificationsController: could not load', exception);
    } finally {
      isLoading.value = false;
    }
  }

  /// Avisa a quien corresponda (ver [INotificationRepository.send]). Nunca
  /// lanza: que no salga un aviso no debe deshacer lo que lo provocó.
  Future<void> notify({
    required NotificationType type,
    required String message,
    required String projectId,
    String? recipientId,
    String? applicationId,
    String? updateId,
    String? commentId,
  }) async {
    try {
      await repository.send(
        type: type,
        message: message,
        projectId: projectId,
        recipientId: recipientId,
        applicationId: applicationId,
        updateId: updateId,
        commentId: commentId,
      );
    } catch (exception) {
      loggy.error('NotificationsController: could not notify', exception);
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await repository.markAllAsRead();
    } catch (exception) {
      loggy.error('NotificationsController: could not mark read', exception);
    }
    await refresh();
  }
}

/// Atajo para cualquier feature: si la bandeja no está registrada (una
/// prueba que solo monta una pantalla), no hace nada.
Future<void> notify({
  required NotificationType type,
  required String message,
  required String projectId,
  String? recipientId,
  String? applicationId,
  String? updateId,
  String? commentId,
}) async {
  if (!Get.isRegistered<NotificationsController>()) return;
  await Get.find<NotificationsController>().notify(
    type: type,
    message: message,
    projectId: projectId,
    recipientId: recipientId,
    applicationId: applicationId,
    updateId: updateId,
    commentId: commentId,
  );
}
