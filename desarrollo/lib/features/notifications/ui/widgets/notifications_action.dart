import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app_routes.dart';
import '../viewmodels/notifications_controller.dart';

/// Campana de notificaciones para la esquina de cualquier `AppBar`.
///
/// Vive en la feature de notificaciones, no en `core/`, porque necesita su
/// controlador. Si no está registrado —una prueba que solo monta una
/// pantalla— no se dibuja nada en vez de tumbar la pantalla entera.
class NotificationsAction extends StatelessWidget {
  const NotificationsAction({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<NotificationsController>()) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      final unread = Get.find<NotificationsController>().unreadCount.value;
      return IconButton(
        tooltip: 'Notificaciones',
        icon: unread > 0
            ? Badge(
                label: Text('$unread'),
                child: const Icon(Icons.notifications_outlined),
              )
            : const Icon(Icons.notifications_outlined),
        onPressed: () => Get.toNamed(AppRoutes.notifications),
      );
    });
  }
}
