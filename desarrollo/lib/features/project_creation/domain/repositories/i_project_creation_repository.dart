import '../models/project_form_options.dart';

abstract class IProjectCreationRepository {
  /// Catálogos del asistente (etapas, tags sugeridos, roles, candidatos).
  Future<ProjectFormOptions> getFormOptions();
}
