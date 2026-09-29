import '../../domain/models/profile_project.dart';
import '../../domain/models/user_profile.dart';

/// De dónde salen los perfiles de `users` y lo que cuelga de ellos.
///
/// Habla siempre del identificador de cuenta (`users.user_id`), nunca del
/// `_id` de la fila: es el que guardan las demás tablas.
abstract class IProfileSource {
  /// El perfil de una cuenta, con sus contadores. Null si esa cuenta todavía
  /// no tiene fila en `users` (p. ej. una sesión de invitado).
  Future<UserProfile?> getProfile(String userId);

  /// Todas las personas con perfil.
  ///
  /// Devolver la lista entera y filtrar en el cliente es deliberado: la
  /// búsqueda de Explorar es por coincidencia parcial del `user_name`, y
  /// ROBLE solo admite filtros de igualdad.
  Future<List<UserSummary>> getUsers();

  /// Proyectos publicados que esa persona creó o en los que participa.
  Future<List<ProfileProject>> getProjectsOf(String userId);
}
