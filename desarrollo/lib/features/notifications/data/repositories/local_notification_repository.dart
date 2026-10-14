import '../../domain/models/app_notification.dart';
import '../../domain/repositories/i_notification_repository.dart';

/// Notificaciones en memoria, para pruebas sin red. La app usa
/// `RobleNotificationRepository`.
class LocalNotificationRepository implements INotificationRepository {
  final List<AppNotification> _items = [];

  @override
  Future<List<AppNotification>> getAll() async =>
      List.of(_items)..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<int> getUnreadCount() async => _items.where((n) => !n.isRead).length;

  /// Sin destinatarios: en memoria solo hay un teléfono, y todo queda aquí.
  @override
  Future<void> send({
    required NotificationType type,
    required String message,
    required String projectId,
    String? recipientId,
    String? applicationId,
    String? updateId,
    String? commentId,
  }) async {
    _items.add(
      AppNotification(
        id: '${DateTime.now().microsecondsSinceEpoch}',
        type: type,
        message: message,
        createdAt: DateTime.now(),
        projectId: projectId,
      ),
    );
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
