import '../../domain/models/project_application.dart';
import '../../domain/repositories/i_project_application_repository.dart';

class LocalProjectApplicationRepository
    implements IProjectApplicationRepository {
  LocalProjectApplicationRepository()
    : _applications = [
        // Solicitudes pendientes en proyectos PROPIOS (p1, p2, p3), para
        // probar aceptar/rechazar como líder/colíder.
        ProjectApplication(
          id: 'application-1',
          projectId: 'p1',
          applicantId: 'u9',
          applicantName: 'Daniela Salamanca',
          applicantEmail: 'daniela@uni.edu',
          motivation:
              'Puedo aportar experiencia en investigación y arquitectura.',
          availability: 'Part-time',
          roleTitle: 'Analista de datos',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        ProjectApplication(
          id: 'application-3',
          projectId: 'p1',
          applicantId: 'u13',
          applicantName: 'Sofía Ramírez',
          applicantEmail: 'sofia.ramirez@uni.edu',
          motivation:
              'Tengo experiencia en React y me encantaría trabajar en el '
              'domo digital.',
          availability: 'Full-time',
          roleTitle: 'Desarrollador Frontend',
          createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        ),
        ProjectApplication(
          id: 'application-4',
          projectId: 'p2',
          applicantId: 'u14',
          applicantName: 'Julián Restrepo',
          applicantEmail: 'julian.restrepo@uni.edu',
          motivation:
              'Sé Flutter y me interesa mucho el mundo de los cómics '
              'independientes.',
          availability: 'Flexible',
          roleTitle: 'Desarrollador Flutter',
          createdAt: DateTime.now().subtract(const Duration(minutes: 40)),
        ),
        ProjectApplication(
          id: 'application-6',
          projectId: 'p3',
          applicantId: 'u15',
          applicantName: 'Rodrigo Salas',
          applicantEmail: 'rodrigo.salas@uni.edu',
          motivation:
              'Tengo experiencia en modelado 3D y renders arquitectónicos.',
          availability: 'Part-time',
          roleTitle: 'Ilustrador 3D',
          createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        ),

        // Sin postulaciones propias pendientes en proyectos AJENOS (r1-r4):
        // quedan libres para probar el flujo de postularse desde cero.
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
  Future<ProjectApplication?> getOwnApplication({
    required String projectId,
    required String applicantId,
  }) async {
    for (final application in _applications) {
      if (application.projectId == projectId &&
          application.applicantId == applicantId &&
          application.status == ProjectApplicationStatus.pending) {
        return application;
      }
    }
    return null;
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

  @override
  Future<ProjectApplication> update(ProjectApplication application) async {
    final index = _applications.indexWhere((a) => a.id == application.id);
    if (index == -1) {
      throw StateError('No se encontró la postulación.');
    }
    _applications[index] = application;
    return application;
  }

  @override
  Future<void> withdraw(String applicationId) async {
    _applications.removeWhere((a) => a.id == applicationId);
  }
}
