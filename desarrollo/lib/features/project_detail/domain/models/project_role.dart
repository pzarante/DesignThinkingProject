/// Rol que el proyecto todavía busca cubrir.
///
/// Una vacante tiene un número de cupos ([totalSlots]); cada postulación
/// aceptada para este rol ocupa uno ([filledSlots]). Cuando ya no quedan
/// cupos, [isOpen] pasa a false y el rol deja de poder elegirse al
/// postularse.
class ProjectRole {
  const ProjectRole({
    required this.title,
    this.description,
    this.skills = const [],
    this.totalSlots = 1,
    this.filledSlots = 0,
  });

  final String title;

  /// Breve descripción de qué haría la persona en este rol dentro del
  /// proyecto. Es lo que se muestra al hipervincular la vacante desde una
  /// publicación.
  final String? description;

  /// Habilidades esperadas; vacío cuando el rol se declaró sin detallarlas.
  final List<String> skills;

  /// Cuántas personas necesita este rol en total. Lo decide quien publica
  /// la vacante (p. ej. "+2 Frontend Developer" -> totalSlots: 2).
  final int totalSlots;

  /// Cuántos de esos cupos ya se ocuparon con postulaciones aceptadas.
  final int filledSlots;

  int get openSlots => (totalSlots - filledSlots).clamp(0, totalSlots);

  /// Falso cuando ya se aceptaron tantas postulaciones como cupos había.
  bool get isOpen => openSlots > 0;

  ProjectRole copyWith({
    String? title,
    String? description,
    List<String>? skills,
    int? totalSlots,
    int? filledSlots,
  }) {
    return ProjectRole(
      title: title ?? this.title,
      description: description ?? this.description,
      skills: skills ?? this.skills,
      totalSlots: totalSlots ?? this.totalSlots,
      filledSlots: filledSlots ?? this.filledSlots,
    );
  }
}
