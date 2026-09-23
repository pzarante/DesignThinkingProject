import 'package:get/get.dart';

import 'data/repositories/local_notification_repository.dart';
import 'domain/repositories/i_notification_repository.dart';
import 'ui/viewmodels/notifications_controller.dart';

void registerNotifications() {
  Get.put<INotificationRepository>(
    LocalNotificationRepository(),
    permanent: true,
  );
  Get.put(NotificationsController(Get.find()), permanent: true);
}
