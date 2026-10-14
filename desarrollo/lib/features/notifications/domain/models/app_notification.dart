/// Qué pasó. [dbValue] es lo que se guarda en `notifications.notification_type`
/// (la tabla tiene un CHECK con la lista de valores permitidos).
enum NotificationType {
  applicationReceived('application_received', 'Nueva postulación'),
  applicationAccepted('application_accepted', 'Postulación aceptada'),

  /// No se guarda: el CHECK de `notification_type` no lo admite y ROBLE no
  /// deja cambiarlo. Sale de `project_applications` con `status` rejected.
  applicationRejected('application_rejected', 'Postulación no aceptada'),
  projectComment('project_comment', 'Nuevo comentario'),
  projectUpdate('project_update', 'Nueva publicación'),
  pollActivity('poll_activity', 'Nueva encuesta');

  const NotificationType(this.dbValue, this.title);

  final String dbValue;
  final String title;

  static NotificationType? fromDb(Object? value) =>
      values.where((type) => type.dbValue == value).firstOrNull;
}

/// Notificación in-app. Se muestra apilada en NotificationsPage, más
/// reciente arriba.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.message,
    required this.createdAt,
    this.projectId,
    this.isRead = false,
  });

  final String id;
  final NotificationType type;
  final String message;
  final DateTime createdAt;

  /// Proyecto relacionado, si aplica — permite navegar al tocar la tarjeta.
  final String? projectId;

  final bool isRead;

  String get title => type.title;

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      type: type,
      message: message,
      createdAt: createdAt,
      projectId: projectId,
      isRead: isRead ?? this.isRead,
    );
  }
}
