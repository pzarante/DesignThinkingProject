import '../../../domain/models/person.dart';
import '../../../domain/models/project_form_options.dart';
import '../../../domain/models/project_stage_option.dart';
import '../i_project_creation_source.dart';

/// Catálogos sembrados en memoria mientras no haya backend.
///
/// Sustituir por una implementación remota de [IProjectCreationSource] en
/// `project_creation_dependencies.dart` no obliga a tocar nada por encima.
class LocalProjectCreationSource implements IProjectCreationSource {
  static const _options = ProjectFormOptions(
    stages: [
      ProjectStageOption(
        name: 'Idea',
        description: 'Conceptualización o lluvia de ideas iniciales.',
      ),
      ProjectStageOption(
        name: 'Formación de equipo',
        description: 'Buscando integrantes y perfiles clave.',
      ),
      ProjectStageOption(
        name: 'Investigación y Prototipo',
        description:
            'Desarrollando los primeros modelos de prueba física o digital.',
      ),
    ],
    systemTags: ['Ingeniería', 'Robótica', 'Energía', 'Sostenibilidad'],
    communityTags: ['HuertoUrbano', 'Reciclaje', 'MedioAmbiente', 'Campus'],
    roleSuggestions: [
      'Desarrollador Frontend',
      'Diseñador UX/UI',
      'Investigador',
      'Community Manager',
    ],
    availabilityOptions: ['Part-time', 'Full-time', 'Flexible'],
    candidates: [
      Person(id: 'u1', name: 'Laura Méndez'),
      Person(id: 'u2', name: 'Carlos Ruiz'),
      Person(id: 'u3', name: 'María Soto'),
    ],
  );

  @override
  Future<ProjectFormOptions> getFormOptions() async => _options;
}
