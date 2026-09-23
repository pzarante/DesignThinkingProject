enum ProjectApplicationStatus { pending, accepted, rejected }

class ProjectApplication {
  const ProjectApplication({
    required this.id,
    required this.projectId,
    required this.applicantId,
    required this.applicantName,
    required this.applicantEmail,
    required this.motivation,
    required this.availability,
    this.roleTitle,
    this.status = ProjectApplicationStatus.pending,
    required this.createdAt,
  });

  final String id;
  final String projectId;
  final String applicantId;
  final String applicantName;
  final String applicantEmail;
  final String motivation;
  final String availability;

  /// Rol al que aplica, entre los que el proyecto tiene abiertos. Nullable
  /// solo para no romper datos previos a este campo; toda postulación nueva
  /// debe traerlo.
  final String? roleTitle;

  final ProjectApplicationStatus status;
  final DateTime createdAt;

  ProjectApplication copyWith({ProjectApplicationStatus? status}) {
    return ProjectApplication(
      id: id,
      projectId: projectId,
      applicantId: applicantId,
      applicantName: applicantName,
      applicantEmail: applicantEmail,
      motivation: motivation,
      availability: availability,
      roleTitle: roleTitle,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
