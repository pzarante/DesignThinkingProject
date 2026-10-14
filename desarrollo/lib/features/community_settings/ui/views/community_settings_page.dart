import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_form_actions.dart';
import '../../../../core/widgets/app_tag_input.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../home/domain/models/community.dart';
import '../../../home/domain/models/project.dart';
import '../viewmodels/community_settings_controller.dart';

/// Configuración de una comunidad.
class CommunitySettingsPage extends StatefulWidget {
  const CommunitySettingsPage({super.key});

  @override
  State<CommunitySettingsPage> createState() => _CommunitySettingsPageState();
}

class _CommunitySettingsPageState extends State<CommunitySettingsPage> {
  final CommunitySettingsController controller = Get.find();

  @override
  void initState() {
    super.initState();
    final community = Get.arguments as Community?;
    if (community != null) {
      controller.start(community);
    }
  }

  Future<void> _pickProjects() async {
    final selection = await showModalBottomSheet<List<String>>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _ProjectPickerSheet(
        projects: controller.availableProjects.toList(),
        initialSelection: controller.selectedProjectIds.toList(),
      ),
    );
    if (selection == null) return;
    controller.selectedProjectIds.value = selection;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Editar comunidad')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        children: [
          Text('COMUNIDAD', style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Nombre de la comunidad',
            isRequired: true,
            controller: controller.nameField,
            onChanged: (value) => controller.name.value = value,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Descripción',
            controller: controller.descriptionField,
            minLines: 3,
            maxLines: 5,
            onChanged: (value) => controller.description.value = value,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Tags', style: theme.textTheme.labelMedium),
          Obx(
            () => AppTagInput(
              selectedTags: controller.tags.toList(),
              systemTags: controller.suggestedTags.toList(),
              hintText: 'Agregar tags...',
              showSuggestions: false,
              onAdd: controller.addTag,
              onRemove: controller.removeTag,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Identidad visual', style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            child: const Text(
              'La comunidad usa un color plano asignado automáticamente.',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Obx(
            () => SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: controller.isPublic.value,
              onChanged: controller.isSaving.value ? null : (value) => controller.isPublic.value = value,
              title: Text('Comunidad pública', style: theme.textTheme.titleMedium),
              subtitle: const Text('Cualquier estudiante puede unirse libremente.'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Proyectos vinculados', style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          Obx(() {
            final selected = controller.availableProjects
                .where((project) => controller.selectedProjectIds.contains(project.id))
                .toList();

            if (selected.isEmpty) {
              return Text(
                'Todavía no hay proyectos vinculados.',
                style: theme.textTheme.bodyMedium,
              );
            }

            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final project in selected)
                  InputChip(
                    label: Text(project.name),
                    onDeleted: () => controller.toggleProject(project.id),
                  ),
              ],
            );
          }),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: controller.isSaving.value ? null : _pickProjects,
            icon: const Icon(Icons.add),
            label: const Text('Seleccionar proyectos'),
          ),
        ],
      ),
      bottomNavigationBar: Obx(
        () => AppFormActions(
          primaryLabel: 'Guardar cambios',
          onPrimary: controller.canSave && !controller.isSaving.value
              ? () async {
                  final saved = await controller.save();
                  if (saved && mounted) {
                    Get.back();
                  }
                }
              : null,
        ),
      ),
    );
  }
}

class _ProjectPickerSheet extends StatefulWidget {
  const _ProjectPickerSheet({
    required this.projects,
    required this.initialSelection,
  });

  final List<Project> projects;
  final List<String> initialSelection;

  @override
  State<_ProjectPickerSheet> createState() => _ProjectPickerSheetState();
}

class _ProjectPickerSheetState extends State<_ProjectPickerSheet> {
  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.from(widget.initialSelection);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Vincular proyectos a la comunidad',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Selecciona los proyectos de tu portafolio que pertenecen a esta comunidad.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (widget.projects.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.folder_off_outlined,
                        size: 40,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'No tienes proyectos disponibles para vincular.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 350),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.projects.length,
                  itemBuilder: (context, index) {
                    final project = widget.projects[index];
                    final isChecked = _selected.contains(project.id);
                    return CheckboxListTile(
                      value: isChecked,
                      title: Text(project.name),
                      subtitle: project.tags.isNotEmpty
                          ? Text(
                              project.tags.join(' • '),
                              style: theme.textTheme.bodySmall,
                            )
                          : null,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selected.add(project.id);
                          } else {
                            _selected.remove(project.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(_selected.toList()),
                  child: Text(
                    widget.projects.isEmpty
                        ? 'Cerrar'
                        : 'Aplicar (${_selected.length})',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
