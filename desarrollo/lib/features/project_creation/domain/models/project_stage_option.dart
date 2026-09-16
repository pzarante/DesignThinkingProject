/// Etapa en la que puede estar un proyecto al crearse, con la explicación
/// que acompaña a cada opción en el primer paso del asistente.
class ProjectStageOption {
  const ProjectStageOption({required this.name, required this.description});

  final String name;
  final String description;
}
