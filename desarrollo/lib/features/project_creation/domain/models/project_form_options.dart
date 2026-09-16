import 'person.dart';
import 'project_stage_option.dart';

/// Catálogos que el asistente necesita para ofrecer opciones: etapas,
/// etiquetas sugeridas, roles y candidatos a co-líder.
class ProjectFormOptions {
  const ProjectFormOptions({
    required this.stages,
    required this.systemTags,
    required this.communityTags,
    required this.roleSuggestions,
    required this.availabilityOptions,
    required this.candidates,
  });

  const ProjectFormOptions.empty()
    : stages = const [],
      systemTags = const [],
      communityTags = const [],
      roleSuggestions = const [],
      availabilityOptions = const [],
      candidates = const [];

  final List<ProjectStageOption> stages;
  final List<String> systemTags;
  final List<String> communityTags;
  final List<String> roleSuggestions;
  final List<String> availabilityOptions;
  final List<Person> candidates;
}
