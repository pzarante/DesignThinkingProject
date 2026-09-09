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
        tags: ['Tecnología'],
      ),
      Community(
        id: 'c2',
        name: 'Narrativa Digital',
        lastActivity: 'Sin actividad reciente',
        tags: ['Comunicación'],
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
        description:
            'Aplicación móvil que utiliza la cámara para leer y decodificar '
            'códigos QR y de barras en tiempo real, con historial de escaneos '
            'y exportación de datos.',
      ),
      Project(
        id: 'r2',
        name: 'EcoCampus',
        tags: const ['Sostenibilidad'],
        stage: 'Prototipo',
        imageUrl: 'https://picsum.photos/seed/r2/400/225',
        description:
            'Plataforma de seguimiento de la huella de carbono universitaria. '
            'Permite a estudiantes registrar hábitos sostenibles y visualizar '
            'el impacto colectivo del campus.',
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
        description:
            'Herramienta de animación colaborativa en línea. Permite a equipos '
            'crear y editar animaciones frame a frame con control de versiones '
            'integrado y exportación a múltiples formatos.',
      ),
      Project(
        id: 'p2',
        name: 'ComicVerse App',
        tags: const ['Comics'],
        stage: 'Investigación',
        memberCount: 2,
        lastVisitedAt: DateTime.now().subtract(const Duration(hours: 2)),
        imageUrl: 'https://picsum.photos/seed/p2/400/225',
        description:
            'Lector y comunidad de cómics independientes latinoamericanos. '
            'Los autores pueden publicar sus obras y recibir retroalimentación '
            'directa de los lectores.',
      ),
      Project(
        id: 'p3',
        name: 'ArquiSmart',
        tags: const ['Arquitectura'],
        stage: 'Equipo',
        memberCount: 4,
        lastVisitedAt: DateTime.now().subtract(const Duration(days: 3)),
        imageUrl: 'https://picsum.photos/seed/p3/400/225',
        description:
            'Asistente de diseño arquitectónico basado en IA. Genera planos '
            'preliminares a partir de requisitos de espacio y presupuesto, '
            'facilitando la fase inicial del diseño.',
      ),
    ],
  );

  @override
  Future<HomeFeed> getFeed() async => _feed;
}
