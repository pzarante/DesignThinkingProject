import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_cover_picker.dart';
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
          Text('Imagen de portada', style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          Obx(
            () => AppCoverPicker(
              imageUrl: controller.coverUrl.value,
              fileName: controller.coverName.value,
              label: 'Cambiar portada',
              onTap: controller.changeCover,
              onRemove: controller.removeCover,
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

class _ProjectPickerSheet extends StatelessWidget {
  const _ProjectPickerSheet({
    required this.projects,
    required this.initialSelection,
  });

  final List<Project> projects;
  final List<String> initialSelection;

  @override
  Widget build(BuildContext context) {
    final selected = <String>{...initialSelection};

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ListView(
          shrinkWrap: true,
          children: [
            const Text('Seleccionar proyectos vinculados'),
            const SizedBox(height: AppSpacing.sm),
            for (final project in projects)
              CheckboxListTile(
                value: selected.contains(project.id),
                title: Text(project.name),
                onChanged: (value) {
                  final current = List<String>.from(selected);
                  if (value == true) {
                    current.add(project.id);
                  } else {
                    current.remove(project.id);
                  }
                  selected.clear();
                  selected.addAll(current);
                  Navigator.of(context).pop(current);
                },
              ),
          ],
        ),
      ),
    );
  }
}
