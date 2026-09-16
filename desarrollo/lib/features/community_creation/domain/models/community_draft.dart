/// Datos de la comunidad tal como quedan al enviar el formulario.
class CommunityDraft {
  const CommunityDraft({
    required this.name,
    required this.description,
    required this.tags,
    required this.coverUrl,
    required this.isPublic,
    required this.projectIds,
  });

  final String name;
  final String description;
  final List<String> tags;
  final String? coverUrl;

  /// Pública = cualquier estudiante puede unirse libremente.
  final bool isPublic;

  /// Proyectos que la comunidad agrupa; el diseño exige al menos uno.
  final List<String> projectIds;
}
