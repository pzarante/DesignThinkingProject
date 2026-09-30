import '../../../domain/models/community_detail.dart';
import '../i_community_detail_source.dart';

/// Comunidad sembrada en memoria, para pruebas sin red ni sesión.
class LocalCommunityDetailSource implements ICommunityDetailSource {
  final Set<String> _followed = {};

  static final Map<String, CommunityDetail> _communities = {
    'c1': CommunityDetail(
      id: 'c1',
      name: 'Studio Creativo UNI',
      description: 'Proyectos de diseño, narrativa y motion del campus.',
      memberCount: 12,
      projects: [
        CommunityProject(
          id: 'p1',
          name: 'MotionLab',
          stage: 'Prototipo',
          tags: const ['Tecnología'],
          memberCount: 2,
          createdAt: DateTime(2025, 9, 1),
        ),
      ],
    ),
  };

  @override
  Future<CommunityDetail?> getDetail(String communityId) async {
    final community = _communities[communityId];
    if (community == null) return null;
    return community.copyWith(isMember: _followed.contains(communityId));
  }

  @override
  Future<bool> toggleMembership(String communityId) async {
    if (_followed.remove(communityId)) return false;
    _followed.add(communityId);
    return true;
  }
}
