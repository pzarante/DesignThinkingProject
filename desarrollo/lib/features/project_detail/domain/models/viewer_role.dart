/// Relación de quien mira con el proyecto. Es lo único que cambia entre la
/// vista del equipo y la vista pública: la información es la misma, las
/// acciones del pie no.
enum ViewerRole {
  /// Creó el proyecto: ve la configuración, publica y gestiona postulaciones.
  creator,

  /// Co-lidera el proyecto: mismos permisos de gestión que el creador,
  /// excepto quitarlo a él del equipo.
  coLeader,

  /// Forma parte del equipo: publica, pero no configura ni gestiona roles.
  member,

  /// Co-líder: puede publicar, pero no configurar el proyecto.
  coLeader,

  /// No pertenece al proyecto: guarda, sigue y se postula.
  visitor;

  bool get belongsToProject => this != ViewerRole.visitor;

  bool get canConfigure => this == ViewerRole.creator;

  bool get canPublish => this == ViewerRole.creator || this == ViewerRole.coLeader;
}
