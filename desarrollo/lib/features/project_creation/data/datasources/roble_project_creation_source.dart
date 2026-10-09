import '../../../../core/roble_cache.dart';
import '../../domain/models/person.dart';
import '../../domain/models/project_form_options.dart';
import '../../domain/models/project_stage_option.dart';
import 'i_project_creation_source.dart';

/// Catálogos del asistente contra ROBLE.
///
/// `roleSuggestions` y `availabilityOptions` no tienen tabla propia en el
/// esquema (son sugerencias/enum fijos, no datos de usuario), así que quedan
/// como constantes aquí en vez de inventar una tabla para dos listas chicas.
///
/// Va por [RobleTableCache] y no por el cliente directo por dos razones: son
/// las mismas tablas que ya cargó el inicio, y una lectura directa exige
/// sesión —el asistente se prepara al arrancar la app, cuando todavía no hay
/// ninguna, y eso devolvía un 401.
class RobleProjectCreationSource implements IProjectCreationSource {
  RobleProjectCreationSource(this._cache);

  final RobleTableCache _cache;

  static const _roleSuggestions = [
    'Desarrollador Frontend',
    'Diseñador UX/UI',
    'Investigador',
    'Community Manager',
  ];

  static const _availabilityOptions = ['Part-time', 'Full-time', 'Flexible'];

  @override
  Future<ProjectFormOptions> getFormOptions() async {
    final tables = await _cache.readAll(['project_stages', 'tags', 'users']);
    final stageRows = tables[0];
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

    final tagRows = tables[1];
    final systemTags = [
      for (final row in tagRows)
        if (row['tag_type'] == 'system') row['name'] as String,
    ];
    final communityTags = [
      for (final row in tagRows)
        if (row['tag_type'] == 'community') row['name'] as String,
    ];

    final userRows = tables[2];
    final candidates = [
      for (final row in userRows)
        if (row['user_id'] != null)
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
