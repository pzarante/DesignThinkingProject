import '../../domain/models/app_notification.dart';
import '../../domain/repositories/i_notification_repository.dart';

/// Notificaciones en memoria mientras no haya backend/push real.
///
/// Registrado como singleton `permanent: true`: cualquier feature (
/// postulaciones, configuración de proyecto) escribe aquí, y la pantalla de
/// notificaciones lee de la misma instancia.
class LocalNotificationRepository implements INotificationRepository {
  final List<AppNotification> _items = [];

  @override
  Future<List<AppNotification>> getAll() async =>
      List.of(_items)..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<int> getUnreadCount() async => _items.where((n) => !n.isRead).length;

  @override
  Future<void> push(AppNotification notification) async {
    _items.add(notification);
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    final index = _items.indexWhere((n) => n.id == notificationId);
    if (index == -1) return;
    _items[index] = _items[index].copyWith(isRead: true);
  }

  @override
  Future<void> markAllAsRead() async {
    for (var i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(isRead: true);
    }
  }
}
