/// Relación de quien mira con el proyecto. Es lo único que cambia entre la
/// vista del equipo y la vista pública: la información es la misma, las
/// acciones del pie no.
enum ViewerRole {
  /// Creó el proyecto: ve la configuración y publica.
  creator,

  /// Forma parte del equipo: publica, pero no configura.
  member,

  /// Co-líder: puede publicar, pero no configurar el proyecto.
  coLeader,

  /// No pertenece al proyecto: guarda, sigue y se postula.
  visitor;

  bool get belongsToProject => this != ViewerRole.visitor;

  bool get canConfigure => this == ViewerRole.creator;

  bool get canPublish => this == ViewerRole.creator || this == ViewerRole.coLeader;
}
