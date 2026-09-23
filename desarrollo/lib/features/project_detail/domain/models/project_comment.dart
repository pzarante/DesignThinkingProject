/// Comentario público sobre un proyecto.
///
/// `authorName` es "Invitado" para quien comenta sin cuenta: la tabla
/// `comments` no guarda un nombre propio, y un invitado no tiene fila en
/// `users` de la que sacarlo.
class ProjectComment {
  const ProjectComment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String content;
  final DateTime createdAt;
}
