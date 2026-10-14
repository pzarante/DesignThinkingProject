import 'package:roble/roble.dart';

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
  RobleNotificationRepository(this._db, this._cache, this._authRepository);

  final RobleApiDataBase _db;
  final RobleTableCache _cache;
  final IAuthRepository _authRepository;

  static const _table = 'notifications';

  /// Solo una cuenta de verdad tiene bandeja: a un invitado nadie le escribe.
  Future<String?> _me() async {
    if (_authRepository.isAnonymous) return null;
    return (await _authRepository.getLoggedUser())?.id;
  }

  @override
  Future<List<AppNotification>> getAll() async {
    final me = await _me();
    if (me == null) return const [];
    final rows = await _cache.read(_table, filters: {'recipient_id': me});
    return [
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
      NotificationType.applicationAccepted ||
      NotificationType.applicationRejected => {?recipientId},
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
    await _db.update(_table, notificationId, {'is_read': true});
    _cache.invalidate([_table]);
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      for (final n in await getAll()) {
        if (!n.isRead) await _db.update(_table, n.id, {'is_read': true});
      }
    } finally {
      _cache.invalidate([_table]);
    }
  }
}
