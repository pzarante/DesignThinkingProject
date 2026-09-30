/// Una comunidad a la que está vinculado el proyecto.
///
/// Solo el identificador y el nombre: es lo que hace falta para enseñarla en
/// el detalle y para abrir su feed. Lo demás lo carga la feature de la
/// comunidad cuando se entra.
class ProjectCommunity {
  const ProjectCommunity({required this.id, required this.name});

  final String id;
  final String name;
}
