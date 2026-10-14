import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../views/notifications_page.dart';
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
        onPressed: () => _openPanel(context),
      );
    });
  }

  /// Panel que se desliza desde la derecha sobre la pantalla actual.
  void _openPanel(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar notificaciones',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, _, _) => Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: (MediaQuery.sizeOf(context).width * 0.85).clamp(0, 380),
          child: const Material(child: NotificationsPage()),
        ),
      ),
      transitionBuilder: (_, animation, _, child) => SlideTransition(
        position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    );
  }
}
