import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:f_clean_template/core/i_local_preferences.dart';
import 'package:f_clean_template/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:f_clean_template/features/notifications/data/repositories/roble_notification_repository.dart';
import 'package:f_clean_template/features/notifications/domain/models/app_notification.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/fake_roble_server.dart';

FakeRobleServer _project() => FakeRobleServer({
  'projects': [
    {'_id': 'p1', 'name': 'MotionLab', 'creator_id': 'lider'},
  ],
  'project_members': [
    {
      'project_id': 'p1',
      'user_id': 'lider',
      'is_creator': true,
      'status': 'active',
    },
    {
      'project_id': 'p1',
      'user_id': 'colider',
      'is_co_leader': true,
      'status': 'active',
    },
    {'project_id': 'p1', 'user_id': 'dev', 'status': 'active'},
  ],
  'project_followers': [
    {'project_id': 'p1', 'user_id': 'fan', 'status': 'active'},
  ],
});

/// Preferencias en memoria, compartidas como las de un mismo teléfono.
class _Preferences implements ILocalPreferences {
  final Map<String, String> values = {};

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  Future<void> setString(String key, String value) async => values[key] = value;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _phone = _Preferences();

/// El repositorio visto por [userId].
RobleNotificationRepository _as(FakeRobleServer server, String userId) {
  Get.reset();
  registerFakeAuth(id: userId);
  return RobleNotificationRepository(
    server.db,
    server.cache,
    Get.find<IAuthRepository>(),
    _phone,
  );
}

Set<Object?> _recipients(FakeRobleServer server) => {
  for (final row in server.rows('notifications')) row['recipient_id'],
};

void main() {
  tearDown(Get.reset);

  test(
    'una postulación avisa a quienes lideran, no a quien la envía',
    () async {
      final server = _project();

      await _as(server, 'colider').send(
        type: NotificationType.applicationReceived,
        message: 'Ana se postuló como Dev.',
        projectId: 'p1',
      );

      expect(_recipients(server), {'lider'});
      expect(
        server.rows('notifications').single['notification_type'],
        'application_received',
      );
    },
  );

  test('aceptar le llega a quien se postuló y lo ve en su bandeja', () async {
    final server = _project();

    await _as(server, 'lider').send(
      type: NotificationType.applicationAccepted,
      recipientId: 'ana',
      message: 'Te aceptaron como Dev en MotionLab.',
      projectId: 'p1',
    );

    expect(_recipients(server), {'ana'});
    final inbox = _as(server, 'ana');
    expect((await inbox.getAll()).single.title, 'Postulación aceptada');
    expect(await inbox.getUnreadCount(), 1);
    await inbox.markAllAsRead();
    expect(await inbox.getUnreadCount(), 0);
    expect(await _as(server, 'lider').getAll(), isEmpty);
  });

  test(
    'una publicación avisa al equipo y a quienes siguen el proyecto',
    () async {
      final server = _project();

      await _as(server, 'dev').send(
        type: NotificationType.projectUpdate,
        message: 'MotionLab publicó "Avance".',
        projectId: 'p1',
        updateId: 'u1',
      );

      expect(_recipients(server), {'lider', 'colider', 'fan'});
    },
  );

  test(
    'un rechazo sale en la bandeja de quien se postuló sin fila propia',
    () async {
      final server = _project();
      server.rows('project_applications').add({
        '_id': 'a1',
        'project_id': 'p1',
        'applicant_id': 'ana',
        'status': 'rejected',
        'reviewed_at': '2026-10-14T10:00:00Z',
      });

      final inbox = _as(server, 'ana');
      final rejection = (await inbox.getAll()).single;
      expect(rejection.type, NotificationType.applicationRejected);
      expect(rejection.message, contains('MotionLab'));
      expect(await inbox.getUnreadCount(), 1);

      await inbox.markAllAsRead();
      expect(await inbox.getUnreadCount(), 0);
      expect(server.rows('notifications'), isEmpty);
    },
  );
}
