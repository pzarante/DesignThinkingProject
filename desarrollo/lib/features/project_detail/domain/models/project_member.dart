/// Integrante del equipo de un proyecto.
class ProjectMember {
  const ProjectMember({
    required this.id,
    required this.name,
    this.roleLabel,
    this.subtitle,
    this.email,
    this.avatarUrl,
    this.isCreator = false,
    this.isCoLeader = false,
  });

  final String id;
  final String name;

  /// Etiqueta corta del rol en el proyecto, p. ej. "CO-LÍDER" o "ANIMADORA".
  final String? roleLabel;

  /// Línea secundaria del diseño: "Motion Designer · 3er año".
  final String? subtitle;

  /// Correo institucional, usado al postularse a un proyecto.
  final String? email;
  final String? avatarUrl;

  /// Quien creó el proyecto; no se puede quitar del equipo.
  final bool isCreator;
  final bool isCoLeader;

  ProjectMember copyWith({
    String? roleLabel,
    String? subtitle,
    bool? isCoLeader,
  }) {
    return ProjectMember(
      id: id,
      name: name,
      roleLabel: roleLabel ?? this.roleLabel,
      subtitle: subtitle ?? this.subtitle,
      email: email,
      avatarUrl: avatarUrl,
      isCreator: isCreator,
      isCoLeader: isCoLeader ?? this.isCoLeader,
    );
  }
}
