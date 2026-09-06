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
  static const _feed = HomeFeed(
    followedCommunities: [
      Community(id: 'c1', name: 'Studio Creativo UNI'),
      Community(id: 'c2', name: 'Narrativa Digital'),
    ],
    recommendedProjects: [
      Project(
        id: 'r1',
        name: 'Lector de Códigos',
        tags: ['Tecnología'],
        stage: 'Investigación',
      ),
      Project(
        id: 'r2',
        name: 'EcoCampus',
        tags: ['Sostenibilidad'],
        stage: 'Prototipo',
      ),
    ],
    opportunities: [
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
        tags: ['Animación'],
        stage: 'Prototipo',
        memberCount: 3,
      ),
      Project(
        id: 'p2',
        name: 'ComicVerse App',
        tags: ['Comics'],
        stage: 'Investigación',
        memberCount: 2,
      ),
    ],
  );

  @override
  Future<HomeFeed> getFeed() async => _feed;
}
