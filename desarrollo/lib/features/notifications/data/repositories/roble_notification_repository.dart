import 'package:roble/roble.dart';

import '../../../../core/i_local_preferences.dart';
import '../../../../core/roble_cache.dart';
import '../../../auth/domain/repositories/i_auth_repository.dart';
import '../../domain/models/app_notification.dart';
import '../../domain/repositories/i_notification_repository.dart';

/// Notificaciones en la tabla `notifications` de ROBLE: una fila por
/// destinatario, así le llegan a quien corresponde aunque esté en otro
/// teléfono.
///
/// shortcut: no hay push; la bandeja se lee al abrir la app, al cambiar de
/// cuenta y al abrir la pantalla. Sumar un push real si hace falta al
/// instante.
class RobleNotificationRepository implements INotificationRepository {
  RobleNotificationRepository(
    this._db,
    this._cache,
    this._authRepository,
    this._preferences,
  );

  final RobleApiDataBase _db;
  final RobleTableCache _cache;
  final IAuthRepository _authRepository;
  final ILocalPreferences _preferences;

  static const _table = 'notifications';

  /// Hasta cuándo vio esta persona sus rechazos, que no tienen fila propia
  /// donde marcar `is_read`.
  /// shortcut: se recuerda por teléfono; en otro teléfono vuelven a salir
  /// como nuevos. Pasarlo a ROBLE si molesta.
  String _seenKey(String me) => 'notifications.rejected_seen.$me';

  /// Solo una cuenta de verdad tiene bandeja: a un invitado nadie le escribe.
  Future<String?> _me() async {
    if (_authRepository.isAnonymous) return null;
    return (await _authRepository.getLoggedUser())?.id;
  }

  @override
  Future<List<AppNotification>> getAll() async {
    final me = await _me();
    if (me == null) return const [];
    final [rows, rejected] = await _cache.readQueries([
      RobleQuery(_table, {'recipient_id': me}),
      RobleQuery('project_applications', {
        'applicant_id': me,
        'status': 'rejected',
      }),
    ]);
    return [
      ...await _rejections(me, rejected),
      for (final row in rows)
        if (NotificationType.fromDb(row['notification_type']) case final type?)
          AppNotification(
            id: row['_id'] as String,
            type: type,
            message: row['message'] as String,
            createdAt:
                DateTime.tryParse('${row['created_at']}')?.toLocal() ??
                DateTime.now(),
            projectId: row['project_id'] as String?,
            isRead: row['is_read'] == true,
          ),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<AppNotification>> _rejections(
    String me,
    List<Map<String, dynamic>> applications,
  ) async {
    if (applications.isEmpty) return const [];
    final seen = DateTime.tryParse(
      await _preferences.getString(_seenKey(me)) ?? '',
    );
    final projects = await _cache.readQueries([
      for (final a in applications)
        RobleQuery('projects', {'_id': a['project_id']}),
    ]);
    return [
      for (final (i, a) in applications.indexed)
        if (DateTime.tryParse('${a['reviewed_at'] ?? a['updated_at']}')
            case final reviewed?)
          AppNotification(
            id: 'application-${a['_id']}',
            type: NotificationType.applicationRejected,
            message:
                'Tu postulación a ${projects[i].firstOrNull?['name'] ?? 'un proyecto'} '
                'no fue aceptada esta vez.',
            createdAt: reviewed.toLocal(),
            projectId: a['project_id'] as String?,
            isRead: seen != null && !reviewed.isAfter(seen),
          ),
    ];
  }

  @override
  Future<int> getUnreadCount() async =>
      (await getAll()).where((n) => !n.isRead).length;

  @override
  Future<void> send({
    required NotificationType type,
    required String message,
    required String projectId,
    String? recipientId,
    String? applicationId,
    String? updateId,
    String? commentId,
  }) async {
    final actor = (await _authRepository.getLoggedUser())?.id;
    final recipients = switch (type) {
      NotificationType.applicationRejected => throw ArgumentError(
        'Los rechazos no se guardan: salen de project_applications.',
      ),
      NotificationType.applicationAccepted => {?recipientId},
      NotificationType.projectUpdate ||
      NotificationType.pollActivity => await _audience(projectId),
      _ => await _leaders(projectId),
    }..remove(actor);

    final now = DateTime.now().toUtc().toIso8601String();
    try {
      for (final recipient in recipients) {
        await _db.create(_table, {
          'recipient_id': recipient,
          'actor_id': actor,
          'notification_type': type.dbValue,
          'project_id': projectId,
          'application_id': applicationId,
          'update_id': updateId,
          'comment_id': commentId,
          'message': message,
          'is_read': false,
          'created_at': now,
        });
      }
    } finally {
      _cache.invalidate([_table]);
    }
  }

  /// Creador y co-líderes activos; si el proyecto no tiene equipo cargado,
  /// su `creator_id`.
  Future<Set<String>> _leaders(String projectId) async {
    final members = await _cache.read(
      'project_members',
      filters: {'project_id': projectId, 'status': 'active'},
    );
    final leaders = {
      for (final m in members)
        if (m['is_creator'] == true || m['is_co_leader'] == true)
          m['user_id'] as String,
    };
    if (leaders.isNotEmpty) return leaders;
    final project = await _cache.getById('projects', projectId);
    return {?project?['creator_id'] as String?};
  }

  /// Equipo activo y seguidores: a quienes les interesa lo que se publica.
  Future<Set<String>> _audience(String projectId) async {
    final byProject = {'project_id': projectId, 'status': 'active'};
    final [members, followers] = await _cache.readQueries([
      RobleQuery('project_members', byProject),
      RobleQuery('project_followers', byProject),
    ]);
    return {
      for (final row in [...members, ...followers]) row['user_id'] as String,
    };
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    // Un rechazo no tiene fila: se marca con [markAllAsRead].
    if (notificationId.startsWith('application-')) return;
    await _db.update(_table, notificationId, {'is_read': true});
    _cache.invalidate([_table]);
  }

  @override
  Future<void> markAllAsRead() async {
    final me = await _me();
    if (me == null) return;
    try {
      final all = await getAll();
      for (final n in all) {
        if (n.isRead || n.type == NotificationType.applicationRejected) {
          continue;
        }
        await _db.update(_table, n.id, {'is_read': true});
      }
      // La fecha del rechazo más nuevo y no la hora de este teléfono: el
      // reloj de quien rechazó puede ir adelantado.
      final latest = all
          .where((n) => n.type == NotificationType.applicationRejected)
          .map((n) => n.createdAt)
          .fold<DateTime?>(
            null,
            (max, d) => max == null || d.isAfter(max) ? d : max,
          );
      if (latest != null) {
        await _preferences.setString(
          _seenKey(me),
          latest.toUtc().toIso8601String(),
        );
      }
    } finally {
      _cache.invalidate([_table]);
    }
  }
}
