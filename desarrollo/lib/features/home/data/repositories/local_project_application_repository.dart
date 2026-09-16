import '../../domain/models/project_application.dart';
import '../../domain/repositories/i_project_application_repository.dart';

class LocalProjectApplicationRepository
    implements IProjectApplicationRepository {
  LocalProjectApplicationRepository()
      : _applications = [
          const ProjectApplication(
            id: 'application-1',
            projectId: 'p1',
            applicantName: 'Daniela Salamanca',
            applicantEmail: 'daniela@uni.edu',
            motivation:
                'Puedo aportar experiencia en investigación y arquitectura.',
            availability: '6 horas por semana',
          ),
        ];

  final List<ProjectApplication> _applications;

  @override
  Future<List<ProjectApplication>> getForProject(String projectId) async {
    return _applications.where((item) => item.projectId == projectId).toList();
  }

  @override
  Future<ProjectApplication> submit(ProjectApplication application) async {
    _applications.add(application);
    return application;
  }

  @override
  Future<ProjectApplication> updateStatus(
    String applicationId,
    ProjectApplicationStatus status,
  ) async {
    final index = _applications.indexWhere((item) => item.id == applicationId);
    if (index == -1) {
      throw StateError('No se encontró la postulación.');
    }

    final updated = _applications[index].copyWith(status: status);
    _applications[index] = updated;
    return updated;
  }
}