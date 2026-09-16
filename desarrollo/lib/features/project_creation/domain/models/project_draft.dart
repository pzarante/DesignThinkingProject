import 'person.dart';

/// Propuesta de proyecto tal como queda tras recorrer el asistente.
///
/// Es un valor inmutable que arma el controller a partir de su estado
/// reactivo; la pantalla de revisión lee de aquí antes de publicar.
class ProjectDraft {
  const ProjectDraft({
    required this.stage,
    required this.name,
    required this.description,
    required this.tags,
    required this.problem,
    required this.objective,
    required this.scope,
    required this.roles,
    required this.maxMembers,
    required this.availability,
    required this.coLeader,
    required this.coverUrl,
    required this.coverName,
    required this.links,
  });

  final String? stage;
  final String name;
  final String description;
  final List<String> tags;
  final String problem;
  final String objective;
  final String scope;
  final List<String> roles;
  final int maxMembers;
  final String availability;

  /// Co-líder elegido en el paso de equipo. Null equivale a "Asignar después".
  final Person? coLeader;
  final String? coverUrl;
  final String? coverName;
  final List<String> links;
}
