import '../../../../auth/domain/repositories/i_auth_repository.dart';
import '../../../domain/models/project_comment.dart';
import '../../../domain/models/project_detail.dart';
import '../../../domain/models/project_member.dart';
import '../../../domain/models/project_milestone.dart';
import '../../../domain/models/project_role.dart';
import '../../../domain/models/viewer_role.dart';
import '../i_project_detail_source.dart';

/// Detalles sembrados en memoria mientras no haya backend.
///
/// Guarda también lo que publica el asistente de creación, así que un
/// proyecto recién creado abre su detalle con todo lo que se escribió.
class LocalProjectDetailSource implements IProjectDetailSource {
  LocalProjectDetailSource(this._authRepository);

  final IAuthRepository _authRepository;

  final Map<String, Set<String>> _likedBy = {};
  final Map<String, List<ProjectComment>> _comments = {};

  /// Identidad de respaldo de los proyectos sembrados (ComicVerse, ArquiSmart)
  /// y de `getCurrentUser()` si por alguna razón no hay sesión iniciada.
  static const ProjectMember _currentUser = ProjectMember(
    id: 'me',
    name: 'María García',
    roleLabel: 'LÍDER',
    subtitle: 'Líder · 5to año',
    email: 'maria@uni.edu',
    isCreator: true,
  );

  final Map<String, ProjectDetail> _details = {
    'p1': const ProjectDetail(
      projectId: 'p1',
      name: 'MotionLab',
      coverUrl: 'https://picsum.photos/seed/p1/400/225',
      stage: 'Prototipo',
      tags: ['Animación', 'MotionDesign', 'AfterEffects', '3D'],
      creator: ProjectMember(
        id: 'u10',
        name: 'Ana Martínez',
        avatarUrl: 'https://i.pravatar.cc/120?img=47',
        roleLabel: 'LÍDER',
        subtitle: 'Líder · 3er año',
        isCreator: true,
      ),
      description:
          'Estudio experimental de motion design enfocado en el desarrollo '
          'de micro-cortometrajes dinámicos. Colaboramos con diseñadores de '
          'sonido y artistas visuales del campus.',
      problem:
          'El campus genera más de 500 toneladas de residuos al año sin un '
          'sistema eficiente de monitoreo o reciclaje.',
      objective:
          'Publicar un set de 6 piezas de animación tipográfica y geométrica '
          'en la pantalla del domo digital universitario al final del '
          'semestre.',
      progressPercent: 35,
      timeline: [
        ProjectMilestone(
          title: 'Definir alcance',
          status: MilestoneStatus.completado,
          dateLabel: 'Oct 2024',
        ),
        ProjectMilestone(
          title: 'Formar equipo',
          status: MilestoneStatus.enProgreso,
          dateLabel: 'Nov 2024',
        ),
        ProjectMilestone(
          title: 'Investigación inicial',
          status: MilestoneStatus.pendiente,
          dateLabel: 'Dic 2024',
        ),
      ],
      activeMilestones: [
        ActiveMilestone(title: 'Investigación de campo', progressPercent: 75),
        ActiveMilestone(title: 'Prototipo sensor IoT', progressPercent: 30),
      ],
      links: ['vimeo.com/motionlab-uni', 'behance.net/motionlab-uni'],
      members: [
        ProjectMember(
          id: 'u10',
          name: 'Ana Martínez',
          avatarUrl: 'https://i.pravatar.cc/120?img=47',
          roleLabel: 'LÍDER',
          subtitle: 'Motion Designer · 3er año',
          isCreator: true,
        ),
        ProjectMember(
          id: 'u11',
          name: 'Carlos López',
          avatarUrl: 'https://i.pravatar.cc/120?img=12',
          roleLabel: 'CO-LÍDER',
          subtitle: 'Diseñador de Sonido · 4to año',
          isCoLeader: true,
        ),
      ],
      maxMembers: 6,
      openRoles: [
        ProjectRole(
          title: 'Desarrollador Frontend',
          skills: ['React', 'TypeScript', 'Git'],
        ),
        ProjectRole(
          title: 'Diseñador UX',
          skills: ['Figma', 'User Research'],
        ),
        ProjectRole(title: 'Analista de datos', skills: ['Python', 'SQL']),
      ],
      availability: 'Part-time',
      communityName: 'Studio Creativo UNI',
      viewerRole: ViewerRole.creator,
    ),
    'p2': const ProjectDetail(
      projectId: 'p2',
      name: 'ComicVerse App',
      coverUrl: 'https://picsum.photos/seed/p2/400/225',
      stage: 'Investigación',
      tags: ['Comics'],
      creator: _currentUser,
      description:
          'Lector y comunidad de cómics independientes latinoamericanos. '
          'Los autores pueden publicar sus obras y recibir retroalimentación '
          'directa de los lectores.',
      progressPercent: 15,
      members: [
        _currentUser,
        ProjectMember(
          id: 'u12',
          name: 'Diego Soto',
          roleLabel: 'ILUSTRADOR',
          subtitle: 'Ilustrador · 2do año',
        ),
      ],
      maxMembers: 5,
      openRoles: [ProjectRole(title: 'Desarrollador Flutter')],
      availability: 'Flexible',
      viewerRole: ViewerRole.creator,
    ),
    'p3': const ProjectDetail(
      projectId: 'p3',
      name: 'ArquiSmart',
      coverUrl: 'https://picsum.photos/seed/p3/400/225',
      stage: 'Equipo',
      tags: ['Arquitectura'],
      creator: _currentUser,
      description:
          'Asistente de diseño arquitectónico basado en IA. Genera planos '
          'preliminares a partir de requisitos de espacio y presupuesto.',
      members: [_currentUser],
      maxMembers: 4,
      viewerRole: ViewerRole.creator,
    ),
    'r1': const ProjectDetail(
      projectId: 'r1',
      name: 'Lector de Códigos',
      coverUrl: 'https://picsum.photos/seed/r1/400/225',
      stage: 'Investigación',
      tags: ['Tecnología'],
      creator: ProjectMember(
        id: 'u20',
        name: 'Laura Méndez',
        roleLabel: 'LÍDER',
        subtitle: 'Líder · 4to año',
        isCreator: true,
      ),
      description:
          'Aplicación móvil que utiliza la cámara para leer y decodificar '
          'códigos QR y de barras en tiempo real.',
      progressPercent: 45,
      members: [
        ProjectMember(
          id: 'u20',
          name: 'Laura Méndez',
          roleLabel: 'LÍDER',
          subtitle: 'Líder · 4to año',
          isCreator: true,
        ),
      ],
      maxMembers: 4,
      openRoles: [
        ProjectRole(title: 'Desarrollador Móvil', skills: ['Flutter', 'Dart']),
      ],
      viewerRole: ViewerRole.visitor,
    ),
    'r2': const ProjectDetail(
      projectId: 'r2',
      name: 'EcoCampus',
      coverUrl: 'https://picsum.photos/seed/r2/400/225',
      stage: 'Prototipo',
      tags: ['Sostenibilidad'],
      creator: ProjectMember(
        id: 'u21',
        name: 'Carlos Ruiz',
        roleLabel: 'LÍDER',
        subtitle: 'Líder · 5to año',
        isCreator: true,
      ),
      description:
          'Plataforma de seguimiento de la huella de carbono universitaria.',
      progressPercent: 60,
      members: [
        ProjectMember(
          id: 'u21',
          name: 'Carlos Ruiz',
          roleLabel: 'LÍDER',
          subtitle: 'Líder · 5to año',
          isCreator: true,
        ),
      ],
      maxMembers: 8,
      viewerRole: ViewerRole.visitor,
    ),
  };

  @override
  Future<ProjectDetail?> getDetail(String projectId) async =>
      _details[projectId];

  @override
  Future<void> saveDetail(ProjectDetail detail) async =>
      _details[detail.projectId] = detail;

  @override
  Future<ProjectMember> getCurrentUser() async {
    final user = await _authRepository.getLoggedUser();
    if (user == null) return _currentUser;
    return ProjectMember(id: user.id ?? _currentUser.id, name: user.name, email: user.email);
  }

  @override
  Future<({int count, bool likedByMe})> getLikeStatus(String projectId) async {
    final me = (await getCurrentUser()).id;
    final likes = _likedBy[projectId] ?? const {};
    return (count: likes.length, likedByMe: likes.contains(me));
  }

  @override
  Future<int> toggleLike(String projectId) async {
    final me = (await getCurrentUser()).id;
    final likes = _likedBy.putIfAbsent(projectId, () => {});
    if (!likes.remove(me)) likes.add(me);
    return likes.length;
  }

  @override
  Future<List<ProjectComment>> getComments(String projectId) async =>
      List.unmodifiable(_comments[projectId] ?? const []);

  @override
  Future<ProjectComment> addComment(String projectId, String content) async {
    final me = await getCurrentUser();
    final comment = ProjectComment(
      id: 'comment${DateTime.now().microsecondsSinceEpoch}',
      authorId: me.id,
      authorName: me.name,
      content: content,
      createdAt: DateTime.now(),
    );
    (_comments[projectId] ??= []).add(comment);
    return comment;
  }
}
