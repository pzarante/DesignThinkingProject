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
    this.status = ProjectApplicationStatus.pending,
    required this.createdAt,
  });

  final String id;
  final String projectId;

  /// Id del usuario que postula. Necesario para evitar postulaciones
  /// duplicadas y para que "Mis aplicaciones" pueda filtrar por usuario.
  final String applicantId;

  final String applicantName;
  final String applicantEmail;
  final String motivation;
  final String availability;
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
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
