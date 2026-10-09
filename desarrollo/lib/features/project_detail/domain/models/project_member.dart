/// Integrante del equipo de un proyecto.
///
/// [id] es el usuario (`users.user_id`); [membershipId] es la fila de
/// `project_members` que lo vincula a este proyecto. Salir del equipo no
/// borra esa fila: la marca con [status] `left` y [leftAt], para no perder
/// el historial.
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
    this.membershipId,
    this.projectRoleId,
    this.status = activeStatus,
    this.joinedAt,
    this.leftAt,
  });

  static const activeStatus = 'active';

  final String id;
  final String name;

  /// Etiqueta corta del rol en el proyecto, p. ej. "CO-LÍDER" o "ANIMADORA".
  final String? roleLabel;

  /// Línea secundaria del diseño: "Motion Designer · 3er semestre".
  final String? subtitle;

  /// Correo institucional, usado al postularse a un proyecto.
  final String? email;
  final String? avatarUrl;

  /// Quien lidera el proyecto; no se puede quitar del equipo. Empieza siendo
  /// quien lo creó, y pasa a otro integrante si el líder se sale.
  final bool isCreator;
  final bool isCoLeader;

  /// `_id` de la fila de `project_members`. Null en datos en memoria y en el
  /// usuario en sesión cuando se pide fuera de un proyecto.
  final String? membershipId;

  /// Cupo de `project_roles` que ocupa, si entró por una postulación.
  final String? projectRoleId;

  /// `active` mientras forma parte del equipo; `left` o `removed` después.
  final String status;
  final DateTime? joinedAt;
  final DateTime? leftAt;

  bool get isActive => status == activeStatus;

  ProjectMember copyWith({
    String? roleLabel,
    String? subtitle,
    bool? isCreator,
    bool? isCoLeader,
  }) {
    return ProjectMember(
      id: id,
      name: name,
      roleLabel: roleLabel ?? this.roleLabel,
      subtitle: subtitle ?? this.subtitle,
      email: email,
      avatarUrl: avatarUrl,
      isCreator: isCreator ?? this.isCreator,
      isCoLeader: isCoLeader ?? this.isCoLeader,
      membershipId: membershipId,
      projectRoleId: projectRoleId,
      status: status,
      joinedAt: joinedAt,
      leftAt: leftAt,
    );
  }
}
