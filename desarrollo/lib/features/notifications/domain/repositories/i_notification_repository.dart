import '../models/app_notification.dart';

abstract class INotificationRepository {
  Future<List<AppNotification>> getAll();
  Future<int> getUnreadCount();
  Future<void> push(AppNotification notification);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead();
}
