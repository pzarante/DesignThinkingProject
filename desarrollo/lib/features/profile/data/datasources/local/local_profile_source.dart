import '../../../domain/models/profile_project.dart';
import '../../../domain/models/user_profile.dart';
import '../i_profile_source.dart';

/// Perfiles sembrados en memoria, para pruebas sin red ni sesión de ROBLE.
///
/// El identificador `me` es el mismo que usa la sesión falsa de las pruebas
/// (`test/support/fake_auth_repository.dart`), para que el perfil propio no
/// salga vacío ahí.
class LocalProfileSource implements IProfileSource {
  static final List<UserProfile> _users = [
    UserProfile(
      userId: 'me',
      userName: 'mariagarcia',
      firstName: 'María',
      lastName: 'García',
      email: 'maria@uni.edu',
      career: 'Ingeniería de Sistemas',
      academicYear: 4,
      bio: 'Me interesa el diseño de producto y la accesibilidad.',
      joinedAt: DateTime(2025, 3, 14),
      stats: const ProfileStats(
        createdProjects: 2,
        memberships: 1,
        communities: 2,
      ),
    ),
    UserProfile(
      userId: 'u2',
      userName: 'anamartinez',
      firstName: 'Ana',
      lastName: 'Martínez',
      email: 'ana@uni.edu',
      career: 'Diseño Industrial',
      academicYear: 3,
      bio: 'Prototipado rápido y motion design.',
      joinedAt: DateTime(2025, 1, 8),
      stats: const ProfileStats(
        createdProjects: 1,
        memberships: 3,
        communities: 1,
      ),
    ),
  ];

  static final Map<String, List<ProfileProject>> _projectsByUser = {
    'me': [
      ProfileProject(
        id: 'p1',
        name: 'MotionLab',
        stage: 'Prototipo',
        tags: const ['Tecnología'],
        memberCount: 2,
        createdAt: DateTime.now().subtract(const Duration(days: 12)),
        isCreator: true,
      ),
    ],
  };

  @override
  Future<UserProfile?> getProfile(String userId) async =>
      _users.where((user) => user.userId == userId).firstOrNull;

  @override
  Future<List<UserSummary>> getUsers() async => [
    for (final user in _users)
      UserSummary(
        userId: user.userId,
        userName: user.userName,
        fullName: user.displayName,
        avatarUrl: user.avatarUrl,
        career: user.career,
      ),
  ];

  @override
  Future<List<ProfileProject>> getProjectsOf(String userId) async =>
      _projectsByUser[userId] ?? const [];
}
