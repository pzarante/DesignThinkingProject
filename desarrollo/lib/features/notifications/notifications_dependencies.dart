import 'package:get/get.dart';

import 'data/repositories/local_notification_repository.dart';
import 'data/repositories/roble_notification_repository.dart';
import 'domain/repositories/i_notification_repository.dart';
import 'ui/viewmodels/notifications_controller.dart';

/// [remote] elige entre ROBLE (la app) y la bandeja en memoria (pruebas sin
/// red). Va después de `registerAuth`: la bandeja es de quien tiene sesión.
void registerNotifications({bool remote = true}) {
  Get.put<INotificationRepository>(
    remote
        ? RobleNotificationRepository(Get.find(), Get.find(), Get.find())
        : LocalNotificationRepository(),
    permanent: true,
  );
  Get.put(NotificationsController(Get.find()), permanent: true);
}
