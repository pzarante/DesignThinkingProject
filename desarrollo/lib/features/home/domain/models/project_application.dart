enum ProjectApplicationStatus { pending, accepted, rejected }

class ProjectApplication {
  const ProjectApplication({
    required this.id,
    required this.projectId,
    required this.applicantName,
    required this.applicantEmail,
    required this.motivation,
    required this.availability,
    this.status = ProjectApplicationStatus.pending,
  });

  final String id;
  final String projectId;
  final String applicantName;
  final String applicantEmail;
  final String motivation;
  final String availability;
  final ProjectApplicationStatus status;

  ProjectApplication copyWith({ProjectApplicationStatus? status}) {
    return ProjectApplication(
      id: id,
      projectId: projectId,
      applicantName: applicantName,
      applicantEmail: applicantEmail,
      motivation: motivation,
      availability: availability,
      status: status ?? this.status,
    );
  }
}