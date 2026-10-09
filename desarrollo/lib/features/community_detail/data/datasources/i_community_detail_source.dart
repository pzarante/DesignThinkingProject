import '../../domain/models/community_detail.dart';

abstract class ICommunityDetailSource {
  /// La comunidad con sus proyectos, o null si no existe.
  Future<CommunityDetail?> getDetail(String communityId);

  /// Sigue o deja de seguir la comunidad. Devuelve si quedó siguiéndola.
  ///
  /// Quien la creó no puede dejar de seguirla: perdería su propia comunidad.
  Future<bool> toggleMembership(String communityId);
}
