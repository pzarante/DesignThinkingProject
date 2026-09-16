import '../../domain/models/project_application.dart';
import '../../domain/repositories/i_project_application_repository.dart';

class LocalProjectApplicationRepository
    implements IProjectApplicationRepository {
  LocalProjectApplicationRepository()
    : _applications = [
        ProjectApplication(
          id: 'application-1',
          projectId: 'p1',
          applicantId: 'u9',
          applicantName: 'Daniela Salamanca',
          applicantEmail: 'daniela@uni.edu',
          motivation:
              'Puedo aportar experiencia en investigación y arquitectura.',
          availability: '6 horas por semana',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];

  final List<ProjectApplication> _applications;

  @override
  Future<List<ProjectApplication>> getForProject(String projectId) async {
    return _applications.where((a) => a.projectId == projectId).toList();
  }

  @override
  Future<List<ProjectApplication>> getForUser(String applicantId) async {
    return _applications.where((a) => a.applicantId == applicantId).toList();
  }

  @override
  Future<bool> hasApplied({
    required String projectId,
    required String applicantId,
  }) async {
    return _applications.any(
      (a) => a.projectId == projectId && a.applicantId == applicantId,
    );
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
    final index = _applications.indexWhere((a) => a.id == applicationId);
    if (index == -1) {
      throw StateError('No se encontró la postulación.');
    }
    final updated = _applications[index].copyWith(status: status);
    _applications[index] = updated;
    return updated;
  }
}
