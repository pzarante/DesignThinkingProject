import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_cover_picker.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_form_actions.dart';
import '../../../../core/widgets/app_tag_input.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../viewmodels/community_creation_controller.dart';
import '../widgets/project_picker_sheet.dart';

/// Formulario único de creación de comunidad.
class CommunityFormPage extends StatefulWidget {
  const CommunityFormPage({super.key});

  @override
  State<CommunityFormPage> createState() => _CommunityFormPageState();
}

class _CommunityFormPageState extends State<CommunityFormPage> {
  final CommunityCreationController controller = Get.find();

  @override
  void initState() {
    super.initState();
    controller.startDraft();
  }

  Future<void> _pickProjects() async {
    final selection = await showModalBottomSheet<List<String>>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => ProjectPickerSheet(
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
      appBar: AppBar(title: const Text('Crear comunidad')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        children: [
          Text('COMUNIDAD', style: theme.textTheme.headlineSmall),
          Text(
            'Nueva comunidad',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Nombre de la comunidad',
            isRequired: true,
            controller: controller.nameField,
            hintText: 'Club de Innovación Social',
            onChanged: (value) => controller.name.value = value,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Descripción',
            controller: controller.descriptionField,
            minLines: 3,
            maxLines: 5,
            hintText: '¿Para qué se reúne esta comunidad?',
            onChanged: (value) => controller.description.value = value,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Tags de la comunidad', style: theme.textTheme.labelMedium),
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
              label: 'Haz click para subir portada',
              onTap: controller.pickPlaceholderCover,
              onRemove: controller.removeCover,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Obx(
            () => SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: controller.isPublic.value,
              onChanged: controller.setPublic,
              title: Text(
                'Comunidad pública',
                style: theme.textTheme.titleMedium,
              ),
              subtitle: const Text(
                'Cualquier estudiante puede unirse libremente.',
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Proyectos de la comunidad',
            style: theme.textTheme.labelMedium,
          ),
          Text(
            'Mínimo 1 proyecto requerido',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Obx(() {
            final selected = controller.selectedProjects;

            if (controller.availableProjects.isEmpty) {
              return AppEmptyState(
                icon: Icons.folder_outlined,
                title: 'No tienes proyectos aún',
                message:
                    'Crea tu primer proyecto para poder vincularlo a esta '
                    'comunidad.',
                action: FilledButton.icon(
                  onPressed: _openProjectWizard,
                  icon: const Icon(Icons.add),
                  label: const Text('Crear nuevo proyecto'),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Proyectos seleccionados:',
                  style: theme.textTheme.labelMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                if (selected.isEmpty)
                  Text(
                    'Todavía no has vinculado ninguno.',
                    style: theme.textTheme.bodySmall,
                  )
                else
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final project in selected)
                        InputChip(
                          label: Text(project.name),
                          onDeleted: () =>
                              controller.removeProject(project.id),
                        ),
                    ],
                  ),
              ],
            );
          }),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: _pickProjects,
            icon: const Icon(Icons.add),
            label: const Text('Seleccionar proyecto existente'),
          ),
          TextButton.icon(
            onPressed: _openProjectWizard,
            icon: const Icon(Icons.add),
            label: const Text('Crear nuevo proyecto'),
          ),
        ],
      ),
      bottomNavigationBar: Obx(
        () => AppFormActions(
          primaryLabel: 'Crear comunidad',
          onPrimary: controller.canSubmit && !controller.isSaving.value
              ? _submit
              : null,
        ),
      ),
    );
  }

  void _openProjectWizard() {
    Get.toNamed(
      AppRoutes.createProject,
      arguments: const {'fromCommunity': true},
    );
  }

  Future<void> _submit() async {
    final community = await controller.create();
    Get.offNamed(AppRoutes.createCommunitySuccess, arguments: community);
  }
}
