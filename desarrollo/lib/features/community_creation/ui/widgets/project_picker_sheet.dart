import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_tag_chip.dart';
import '../../../home/domain/models/project.dart';

/// Hoja inferior para vincular proyectos a la comunidad.
///
/// Trabaja sobre una copia de la selección y solo la devuelve al confirmar,
/// para que cerrar la hoja no altere el formulario.
class ProjectPickerSheet extends StatefulWidget {
  const ProjectPickerSheet({
    super.key,
    required this.projects,
    required this.initialSelection,
  });

  final List<Project> projects;
  final List<String> initialSelection;

  @override
  State<ProjectPickerSheet> createState() => _ProjectPickerSheetState();
}

class _ProjectPickerSheetState extends State<ProjectPickerSheet> {
  late final Set<String> _selection = {...widget.initialSelection};
  final TextEditingController _queryField = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _queryField.dispose();
    super.dispose();
  }

  List<Project> get _matches {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.projects;
    return widget.projects
        .where((project) => project.name.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final matches = _matches;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vincular proyectos', style: theme.textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _queryField,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    hintText: 'Buscar proyectos...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: matches.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      'Ningún proyecto coincide con la búsqueda.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: matches.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final project = matches[index];
                      final isSelected = _selection.contains(project.id);

                      return CheckboxListTile(
                        value: isSelected,
                        title: Text(project.name),
                        subtitle: project.tags.isEmpty
                            ? null
                            : Align(
                                alignment: Alignment.centerLeft,
                                child: AppTagChip(label: project.tags.first),
                              ),
                        onChanged: (_) => setState(() {
                          isSelected
                              ? _selection.remove(project.id)
                              : _selection.add(project.id);
                        }),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () =>
                      Navigator.of(context).pop(_selection.toList()),
                  child: const Text('Confirmar selección'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
