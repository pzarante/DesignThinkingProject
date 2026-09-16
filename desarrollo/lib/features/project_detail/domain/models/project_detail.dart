import 'project_member.dart';
import 'project_milestone.dart';
import 'project_role.dart';
import 'viewer_role.dart';

/// Toda la información que se muestra de un proyecto ya publicado.
///
/// Es el modelo propio de esta feature: el feed trabaja con su propia
/// entidad resumida, y aquí vive la versión completa (problema, objetivo,
/// cronograma, equipo y roles) que alimenta las tres pestañas.
class ProjectDetail {
  const ProjectDetail({
    required this.projectId,
    required this.name,
    this.creator,
    this.coverUrl,
    this.stage,
    this.tags = const [],
    this.description,
    this.problem,
    this.objective,
    this.scope,
    this.progressPercent = 0,
    this.timeline = const [],
    this.activeMilestones = const [],
    this.links = const [],
    this.members = const [],
    this.maxMembers = 0,
    this.openRoles = const [],
    this.availability,
    this.communityName,
    this.viewerRole = ViewerRole.visitor,
  });

  final String projectId;
  final String name;
  final String? coverUrl;

  /// Etapa actual, tal como la eligió quien creó el proyecto.
  final String? stage;
  final List<String> tags;

  /// Quien creó el proyecto; se muestra bajo el título en todas las
  /// pestañas. Null cuando el proyecto todavía no tiene detalle guardado y
  /// solo se conoce lo que trae el feed.
  final ProjectMember? creator;

  final String? description;
  final String? problem;
  final String? objective;
  final String? scope;

  /// Avance declarado del proyecto, 0-100.
  final int progressPercent;

  /// Pasos del cronograma. Vacío mientras el proyecto no defina ninguno.
  final List<ProjectMilestone> timeline;
  final List<ActiveMilestone> activeMilestones;
  final List<String> links;

  final List<ProjectMember> members;

  /// Tamaño máximo del equipo; alimenta "Integrantes (2/6)".
  final int maxMembers;
  final List<ProjectRole> openRoles;

  /// Dedicación esperada del equipo, p. ej. "Part-time".
  final String? availability;

  /// Comunidad a la que está vinculado, si lo está.
  final String? communityName;

  final ViewerRole viewerRole;

  /// Co-líder actual, si se asignó uno.
  ProjectMember? get coLeader {
    for (final member in members) {
      if (member.isCoLeader) return member;
    }
    return null;
  }

  ProjectDetail copyWith({
    String? name,
    String? description,
    String? stage,
    List<String>? tags,
    List<ProjectMember>? members,
    List<ProjectRole>? openRoles,
    String? coverUrl,
    bool clearCommunity = false,
    String? communityName,
  }) {
    return ProjectDetail(
      projectId: projectId,
      name: name ?? this.name,
      coverUrl: coverUrl ?? this.coverUrl,
      stage: stage ?? this.stage,
      tags: tags ?? this.tags,
      creator: creator,
      description: description ?? this.description,
      problem: problem,
      objective: objective,
      scope: scope,
      progressPercent: progressPercent,
      timeline: timeline,
      activeMilestones: activeMilestones,
      links: links,
      members: members ?? this.members,
      maxMembers: maxMembers,
      openRoles: openRoles ?? this.openRoles,
      availability: availability,
      communityName: clearCommunity
          ? null
          : (communityName ?? this.communityName),
      viewerRole: viewerRole,
    );
  }
}
