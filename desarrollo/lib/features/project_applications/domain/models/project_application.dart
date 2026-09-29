enum ProjectApplicationStatus {
  pending,
  accepted,
  rejected;

  /// Lee `project_applications.status`, que guarda el [name] de cada valor.
  static ProjectApplicationStatus fromWire(Object? value) =>
      ProjectApplicationStatus.values.firstWhere(
        (status) => status.name == value,
        orElse: () => ProjectApplicationStatus.pending,
      );
}

/// Postulación de alguien a un cupo concreto de un proyecto.
///
/// En ROBLE la fila solo guarda [projectRoleId] (el cupo de `project_roles`);
/// [projectId] y [roleTitle] se resuelven desde ese cupo al leerla, y el
/// nombre y correo de quien se postula, desde `users`.
class ProjectApplication {
  const ProjectApplication({
    required this.id,
    required this.projectId,
    required this.projectRoleId,
    required this.applicantId,
    required this.applicantName,
    required this.applicantEmail,
    required this.motivation,
    required this.availability,
    this.roleTitle,
    this.status = ProjectApplicationStatus.pending,
    this.reviewedBy,
    required this.createdAt,
  });

  final String id;
  final String projectId;

  /// Cupo de `project_roles` al que aplica. Al aceptarse se ocupa este cupo,
  /// o cualquier otro libre del mismo rol si este ya se llenó.
  final String projectRoleId;

  final String applicantId;
  final String applicantName;
  final String applicantEmail;
  final String motivation;
  final String availability;

  /// Nombre del rol de [projectRoleId], solo para mostrar. Null si el cupo
  /// se borró mientras la postulación esperaba respuesta.
  final String? roleTitle;

  final ProjectApplicationStatus status;

  /// Quien aceptó o rechazó la postulación.
  final String? reviewedBy;
  final DateTime createdAt;

  ProjectApplication copyWith({
    ProjectApplicationStatus? status,
    String? projectRoleId,
    String? roleTitle,
    String? motivation,
    String? availability,
    String? reviewedBy,
  }) {
    return ProjectApplication(
      id: id,
      projectId: projectId,
      projectRoleId: projectRoleId ?? this.projectRoleId,
      applicantId: applicantId,
      applicantName: applicantName,
      applicantEmail: applicantEmail,
      motivation: motivation ?? this.motivation,
      availability: availability ?? this.availability,
      roleTitle: roleTitle ?? this.roleTitle,
      status: status ?? this.status,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      createdAt: createdAt,
    );
  }
}
