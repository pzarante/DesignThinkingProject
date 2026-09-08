import '../../../domain/models/community.dart';
import '../../../domain/models/home_feed.dart';
import '../../../domain/models/opportunity.dart';
import '../../../domain/models/project.dart';
import '../i_home_source.dart';

/// Seeded in-memory feed used while the home screen has no backend.
///
/// Swap this for a remote [IHomeSource] in `home_dependencies.dart`; nothing
/// above this class needs to change.
class LocalHomeSource implements IHomeSource {
  static final _feed = HomeFeed(
    followedCommunities: const [
      Community(
        id: 'c1',
        name: 'Studio Creativo UNI',
        lastActivity: '3 publicaciones nuevas',
      ),
      Community(
        id: 'c2',
        name: 'Narrativa Digital',
        lastActivity: 'Sin actividad reciente',
      ),
    ],
    recommendedProjects: [
      Project(
        id: 'r1',
        name: 'Lector de Códigos',
        tags: const ['Tecnología'],
        stage: 'Investigación',
        imageUrl: 'https://picsum.photos/seed/r1/400/225',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Project(
        id: 'r2',
        name: 'EcoCampus',
        tags: const ['Sostenibilidad'],
        stage: 'Prototipo',
        imageUrl: 'https://picsum.photos/seed/r2/400/225',
      ),
    ],
    opportunities: const [
      Opportunity(
        id: 'o1',
        name: 'Feria de Innovación 2025',
        participatingProjects: 15,
      ),
    ],
    myProjects: [
      Project(
        id: 'p1',
        name: 'MotionLab',
        tags: const ['Animación'],
        stage: 'Prototipo',
        memberCount: 3,
        isPinned: true,
        imageUrl: 'https://picsum.photos/seed/p1/400/225',
      ),
      Project(
        id: 'p2',
        name: 'ComicVerse App',
        tags: const ['Comics'],
        stage: 'Investigación',
        memberCount: 2,
        lastVisitedAt: DateTime.now().subtract(const Duration(hours: 2)),
        imageUrl: 'https://picsum.photos/seed/p2/400/225',
      ),
      Project(
        id: 'p3',
        name: 'ArquiSmart',
        tags: const ['Arquitectura'],
        stage: 'Equipo',
        memberCount: 4,
        lastVisitedAt: DateTime.now().subtract(const Duration(days: 3)),
        imageUrl: 'https://picsum.photos/seed/p3/400/225',
      ),
    ],
  );

  @override
  Future<HomeFeed> getFeed() async => _feed;
}
