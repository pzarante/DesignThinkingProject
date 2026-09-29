/// Rol que el proyecto busca cubrir, tal como se muestra: "Frontend · 1/2".
///
/// En ROBLE cada cupo es una fila propia de `project_roles`: "+2 Frontend
/// Developer" son dos filas con el mismo `name`, cada una con su `status` y
/// su `assigned_user_id`. Este modelo es el rol ya agrupado por nombre;
/// [slotIds] y [openSlotIds] guardan qué filas lo forman para poder escribir
/// de vuelta sobre ellas. Un rol recién agregado en la configuración, que
/// todavía no se guarda, llega con ambas listas vacías.
class ProjectRole {
  const ProjectRole({
    required this.title,
    this.description,
    this.skills = const [],
    this.totalSlots = 1,
    this.filledSlots = 0,
    this.slotIds = const [],
    this.openSlotIds = const [],
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

  /// `_id` de cada fila de `project_roles` que forma este rol, una por cupo.
  final List<String> slotIds;

  /// Las filas de [slotIds] que siguen sin nadie asignado.
  final List<String> openSlotIds;

  int get openSlots => (totalSlots - filledSlots).clamp(0, totalSlots);

  /// Falso cuando ya se aceptaron tantas postulaciones como cupos había.
  bool get isOpen => openSlots > 0;

  /// Cupo al que apunta una postulación nueva a este rol. Null en los datos
  /// en memoria, donde los roles no tienen filas propias.
  String? get firstOpenSlotId => openSlotIds.isEmpty ? null : openSlotIds.first;

  /// Si la fila [projectRoleId] es uno de los cupos de este rol.
  bool hasSlot(String projectRoleId) => slotIds.contains(projectRoleId);

  ProjectRole copyWith({
    String? title,
    String? description,
    List<String>? skills,
    int? totalSlots,
    int? filledSlots,
    List<String>? slotIds,
    List<String>? openSlotIds,
  }) {
    return ProjectRole(
      title: title ?? this.title,
      description: description ?? this.description,
      skills: skills ?? this.skills,
      totalSlots: totalSlots ?? this.totalSlots,
      filledSlots: filledSlots ?? this.filledSlots,
      slotIds: slotIds ?? this.slotIds,
      openSlotIds: openSlotIds ?? this.openSlotIds,
    );
  }
}
