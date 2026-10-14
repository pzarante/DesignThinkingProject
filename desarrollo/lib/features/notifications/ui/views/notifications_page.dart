import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../home/domain/models/project.dart';
import '../../../home/ui/viewmodels/home_controller.dart';
import '../../domain/models/app_notification.dart';
import '../viewmodels/notifications_controller.dart';
import '../widgets/notification_card.dart';

/// Bandeja de notificaciones. Se abre como panel lateral desde la campana
/// (`NotificationsAction`), así que trae su propio encabezado con cerrar.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationsController controller = Get.find();

  @override
  void initState() {
    super.initState();
    // Leer no es abrir el panel: cada una se marca al tocarla, o todas con
    // el botón.
    controller.refresh();
  }

  /// Marca como leída y, si es de un proyecto, lo abre.
  void _open(AppNotification notification) {
    controller.markAsRead(notification);
    final projectId = notification.projectId;
    if (projectId == null) return;
    Navigator.of(context).maybePop();
    Get.toNamed(AppRoutes.projectDetail, arguments: _projectFor(projectId));
  }

  /// La tarjeta del feed si está a mano; si no, el detalle carga solo con
  /// el id.
  Project _projectFor(String id) {
    if (Get.isRegistered<HomeController>()) {
      final feed = Get.find<HomeController>().feed;
      for (final project in [
        ...feed.myProjects,
        ...feed.savedProjects,
        ...feed.recommendedProjects,
      ]) {
        if (project.id == id) return project;
      }
    }
    return Project(id: id, name: '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.xs,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Notificaciones',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Obx(() {
                final unread = controller.unreadCount.value;
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        unread == 0
                            ? 'Estás al día'
                            : unread == 1
                            ? '1 sin leer'
                            : '$unread sin leer',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: unread == 0 ? null : controller.markAllAsRead,
                      icon: const Icon(Icons.done_all, size: 18),
                      label: const Text('Marcar todas'),
                    ),
                  ],
                );
              }),
            ),
            const Divider(height: 1),
            Expanded(
              child: Obx(() {
                final items = controller.items.toList();
                if (items.isEmpty && controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                return RefreshIndicator(
                  onRefresh: controller.refresh,
                  child: items.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          children: const [
                            SizedBox(height: AppSpacing.xl),
                            AppEmptyState(
                              icon: Icons.notifications_none_outlined,
                              title: 'No hay nada nuevo',
                              message:
                                  'Aquí verás postulaciones, respuestas, '
                                  'comentarios y publicaciones de tus '
                                  'proyectos.',
                            ),
                          ],
                        )
                      : _list(items, theme),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  /// Primero las nuevas y luego las anteriores, cada grupo con su título.
  Widget _list(List<AppNotification> items, ThemeData theme) {
    final fresh = items.where((n) => !n.isRead).toList();
    final seen = items.where((n) => n.isRead).toList();
    Widget label(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
    Widget card(AppNotification n) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: NotificationCard(notification: n, onTap: () => _open(n)),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        0,
        AppSpacing.sm,
        AppSpacing.lg,
      ),
      children: [
        if (fresh.isNotEmpty) ...[label('Nuevas'), ...fresh.map(card)],
        if (seen.isNotEmpty) ...[label('Anteriores'), ...seen.map(card)],
      ],
    );
  }
}
