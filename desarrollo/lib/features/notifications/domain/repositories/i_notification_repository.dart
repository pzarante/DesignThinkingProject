import '../models/app_notification.dart';

abstract class INotificationRepository {
  /// Las de quien tiene sesión, la más reciente primero.
  Future<List<AppNotification>> getAll();
  Future<int> getUnreadCount();

  /// Avisa a quien le toca según [type]: a quienes lideran el proyecto
  /// (postulaciones, comentarios, salidas), a quienes lo siguen o integran
  /// (publicaciones, encuestas) o a [recipientId] (respuesta a una
  /// postulación). Nunca a quien lo provocó.
  Future<void> send({
    required NotificationType type,
    required String message,
    required String projectId,
    String? recipientId,
    String? applicationId,
    String? updateId,
    String? commentId,
  });

  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead();
}
