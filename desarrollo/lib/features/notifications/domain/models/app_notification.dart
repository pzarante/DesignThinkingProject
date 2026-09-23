enum NotificationType {
  newApplication,
  applicationAccepted,
  applicationRejected,
  memberJoined,
  memberLeft,
}

/// Notificación in-app. Se muestra apilada en NotificationsPage, más
/// reciente arriba.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.projectId,
    this.isRead = false,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;

  /// Proyecto relacionado, si aplica — permite navegar al tocar la tarjeta.
  final String? projectId;

  final bool isRead;

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      message: message,
      createdAt: createdAt,
      projectId: projectId,
      isRead: isRead ?? this.isRead,
    );
  }
}
