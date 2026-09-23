import 'package:roble/roble.dart';

import '../../domain/models/person.dart';
import '../../domain/models/project_form_options.dart';
import '../../domain/models/project_stage_option.dart';
import 'i_project_creation_source.dart';

/// Catálogos del asistente contra ROBLE.
///
/// `roleSuggestions` y `availabilityOptions` no tienen tabla propia en el
/// esquema (son sugerencias/enum fijos, no datos de usuario), así que quedan
/// como constantes aquí en vez de inventar una tabla para dos listas chicas.
class RobleProjectCreationSource implements IProjectCreationSource {
  RobleProjectCreationSource(this._db);

  final RobleApiDataBase _db;

  static const _roleSuggestions = [
    'Desarrollador Frontend',
    'Diseñador UX/UI',
    'Investigador',
    'Community Manager',
  ];

  static const _availabilityOptions = ['Part-time', 'Full-time', 'Flexible'];

  @override
  Future<ProjectFormOptions> getFormOptions() async {
    final stageRows = await _db.read('project_stages');
    stageRows.sort(
      (a, b) => ((a['display_order'] as num?) ?? 0).compareTo(
        (b['display_order'] as num?) ?? 0,
      ),
    );
    final stages = [
      for (final row in stageRows)
        if (row['is_active'] != false)
          ProjectStageOption(
            name: row['name'] as String,
            description: (row['description'] as String?) ?? '',
          ),
    ];

    final tagRows = await _db.read('tags');
    final systemTags = [
      for (final row in tagRows)
        if (row['tag_type'] == 'system') row['name'] as String,
    ];
    final communityTags = [
      for (final row in tagRows)
        if (row['tag_type'] == 'community') row['name'] as String,
    ];

    final userRows = await _db.read('users');
    final candidates = [
      for (final row in userRows)
        Person(
          id: row['user_id'] as String,
          name: (row['user_name'] as String?) ?? 'Sin nombre',
        ),
    ];

    return ProjectFormOptions(
      stages: stages,
      systemTags: systemTags,
      communityTags: communityTags,
      roleSuggestions: _roleSuggestions,
      availabilityOptions: _availabilityOptions,
      candidates: candidates,
    );
  }
}
