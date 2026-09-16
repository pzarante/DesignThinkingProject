/// Rol que el proyecto todavía busca cubrir.
class ProjectRole {
  const ProjectRole({required this.title, this.skills = const []});

  final String title;

  /// Habilidades esperadas; vacío cuando el rol se declaró sin detallarlas.
  final List<String> skills;
}
