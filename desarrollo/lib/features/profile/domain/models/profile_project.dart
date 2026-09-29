/// Un proyecto tal como lo necesita el perfil: portada, nombre, etapa y
/// tamaño del equipo.
///
/// No es el `Project` del feed a propósito: aquí solo hace falta lo que se ve
/// en la tarjeta, y el perfil no debería quedar atado a lo que la feature de
/// inicio decida guardar mañana. La conversión a lo que pide la tarjeta vive
/// en la capa de UI, que es la única que necesita saberlo.
class ProfileProject {
  const ProfileProject({
    required this.id,
    required this.name,
    this.description,
    this.coverUrl,
    this.stage,
    this.tags = const [],
    this.memberCount = 0,
    this.createdAt,
    this.isCreator = false,
  });

  final String id;
  final String name;
  final String? description;
  final String? coverUrl;
  final String? stage;
  final List<String> tags;
  final int memberCount;
  final DateTime? createdAt;

  /// True si esta persona creó el proyecto; false si solo forma parte del
  /// equipo. Separa las dos listas del perfil sin volver a consultar.
  final bool isCreator;
}
