import 'package:get/get.dart';
import 'package:loggy/loggy.dart';

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
    refresh();
    super.onInit();
  }

  @override
  Future<void> refresh() async {
    isLoading.value = true;
    items.value = await repository.getAll();
    unreadCount.value = await repository.getUnreadCount();
    isLoading.value = false;
  }

  /// Llamado desde cualquier feature que necesite avisar algo.
  Future<void> push({
    required NotificationType type,
    required String title,
    required String message,
    String? projectId,
  }) async {
    await repository.push(
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        title: title,
        message: message,
        createdAt: DateTime.now(),
        projectId: projectId,
      ),
    );
    await refresh();
  }

  Future<void> markAllAsRead() async {
    await repository.markAllAsRead();
    await refresh();
  }
}
