/// Una fila de la tabla `users` de ROBLE, ya interpretada.
///
/// Ojo con los dos identificadores: [userId] es `users.user_id`, la cuenta de
/// ROBLE a la que apuntan `projects.creator_id`, `project_members.user_id`,
/// `comments.author_id`… y es el único que sirve para cruzar tablas. El `_id`
/// de la fila (el del perfil en sí) no se usa fuera de esta feature, así que
/// no se expone.
class UserProfile {
  const UserProfile({
    required this.userId,
    required this.userName,
    this.firstName,
    this.lastName,
    this.email,
    this.avatarUrl,
    this.career,
    this.academicYear,
    this.bio,
    this.joinedAt,
    this.stats = const ProfileStats.empty(),
  });

  /// `users.user_id`: la cuenta de ROBLE, no el `_id` de la fila.
  final String userId;

  /// `users.user_name`: el identificador visible, lo que se busca en Explorar.
  final String userName;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? avatarUrl;
  final String? career;

  /// `users.academic_year`, un `smallint`: el semestre de carrera, no una fecha.
  final int? academicYear;
  final String? bio;
  final DateTime? joinedAt;
  final ProfileStats stats;

  /// Nombre y apellido si los hay; si no, el nombre de usuario. Sirve para el
  /// título del perfil, donde dejar un hueco vacío quedaría peor que repetir
  /// el `user_name` que ya aparece debajo.
  String get displayName {
    final full = [
      firstName,
      lastName,
    ].where((part) => part != null && part.trim().isNotEmpty).join(' ');
    return full.isEmpty ? userName : full;
  }

  /// "Ingeniería de Sistemas · 3er semestre", saltando lo que falte.
  String? get academicLine {
    final parts = <String>[
      if (career != null && career!.trim().isNotEmpty) career!.trim(),
      if (academicYear != null) '$academicYearº semestre',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  UserProfile copyWith({ProfileStats? stats}) => UserProfile(
    userId: userId,
    userName: userName,
    firstName: firstName,
    lastName: lastName,
    email: email,
    avatarUrl: avatarUrl,
    career: career,
    academicYear: academicYear,
    bio: bio,
    joinedAt: joinedAt,
    stats: stats ?? this.stats,
  );
}

/// Los tres números del encabezado del perfil.
///
/// Se cuentan en el cliente a partir de `projects`, `project_members` y
/// `community_members`: ROBLE no tiene agregados en la API de tablas.
class ProfileStats {
  const ProfileStats({
    required this.createdProjects,
    required this.memberships,
    required this.communities,
  });

  const ProfileStats.empty()
    : createdProjects = 0,
      memberships = 0,
      communities = 0;

  /// Proyectos donde es `creator_id`.
  final int createdProjects;

  /// Proyectos donde aparece en `project_members` sin haberlos creado.
  final int memberships;

  /// Comunidades activas en `community_members`.
  final int communities;
}

/// Lo justo para pintar un resultado de búsqueda sin traerse los contadores
/// de cada persona: la lista de Explorar puede tener decenas de filas y cada
/// contador serían tres lecturas más.
class UserSummary {
  const UserSummary({
    required this.userId,
    required this.userName,
    this.fullName,
    this.avatarUrl,
    this.career,
  });

  final String userId;
  final String userName;
  final String? fullName;
  final String? avatarUrl;
  final String? career;

  String get displayName =>
      (fullName == null || fullName!.trim().isEmpty) ? userName : fullName!;
}
