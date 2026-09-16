import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_cover_picker.dart';
import '../../../../core/widgets/app_form_actions.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_tag_chip.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../project_applications/ui/viewmodels/applicants_controller.dart';
import '../../domain/models/project_member.dart';
import '../viewmodels/project_settings_controller.dart';
import '../widgets/applications_list.dart';
import '../widgets/project_member_tile.dart';

/// Configuración del proyecto, disponible solo para quien lo creó.
class ProjectSettingsPage extends StatefulWidget {
  const ProjectSettingsPage({super.key});

  @override
  State<ProjectSettingsPage> createState() => _ProjectSettingsPageState();
}

class _ProjectSettingsPageState extends State<ProjectSettingsPage> {
  final ProjectSettingsController controller = Get.find();
  final ApplicantsController applicationController = Get.find();

  @override
  void initState() {
    super.initState();
    applicationController.load(controller.projectId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Configurar proyecto')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        children: [
          const AppSectionHeader(title: 'Información general'),
          AppTextField(
            label: 'Nombre del proyecto',
            controller: controller.nameField,
            onChanged: (value) => controller.name.value = value,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Descripción',
            controller: controller.descriptionField,
            minLines: 3,
            maxLines: 5,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Categoría',
            controller: controller.categoryField,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Imagen de portada', style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          Obx(
            () => AppCoverPicker(
              imageUrl: controller.coverUrl.value,
              fileName: controller.coverName,
              onTap: controller.changeCover,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: controller.changeCover,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Cambiar portada'),
            ),
          ),

          const AppSectionHeader(title: 'Equipo y roles'),
          Obx(
            () => Column(
              children: [
                for (final member in controller.members)
                  ProjectMemberTile(
                    member: member,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Editar rol',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _editRole(context, member),
                        ),
                        IconButton(
                          tooltip: controller.canRemove(member)
                              ? 'Quitar del equipo'
                              : 'No se puede quitar a quien creó el proyecto',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: controller.canRemove(member)
                              ? () => _confirmRemove(context, member)
                              : null,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Invitar integrantes llegará en otra entrega.'),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Agregar miembro'),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(AppSpacing.sm),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Permisos según rol:',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                      Text(
                        'Creador: gestiona roles, agrega y quita miembros.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                      Text(
                        'Co-líder: gestiona roles y agrega, no quita al '
                        'creador.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const AppSectionHeader(title: 'Liderazgo y permisos'),
          Obx(() {
            final coLeader = controller.members
                .where((member) => member.isCoLeader)
                .toList();

            return Card(
              child: ListTile(
                title: Text(
                  coLeader.isEmpty ? 'Sin co-líder' : coLeader.first.name,
                ),
                subtitle: const Text('Co-líder del proyecto'),
                trailing: TextButton(
                  onPressed: () => _changeCoLeader(context),
                  child: const Text('Cambiar'),
                ),
              ),
            );
          }),
          Text(
            'El creador y el co-líder son los únicos que pueden editar las '
            'configuraciones generales del proyecto.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          const AppSectionHeader(title: 'Postulaciones recibidas'),
          ApplicationsList(controller: applicationController),

          const AppSectionHeader(title: 'Comunidad asociada'),
          Obx(() {
            final community = controller.communityName.value;

            if (community == null) {
              return Text(
                'Este proyecto no está vinculado a ninguna comunidad.',
                style: theme.textTheme.bodyMedium,
              );
            }

            return Card(
              child: ListTile(
                leading: const Icon(Icons.groups_outlined),
                title: Text(community),
                subtitle: const Text('Comunidad vinculada'),
                trailing: TextButton(
                  onPressed: controller.unlinkCommunity,
                  child: const Text('Desvincular'),
                ),
              ),
            );
          }),
        ],
      ),
      bottomNavigationBar: Obx(
        () => AppFormActions(
          primaryLabel: 'Guardar cambios',
          onPrimary: controller.isSaving.value
              ? null
              : () async {
                  await controller.save();
                  Get.back();
                  Get.snackbar(
                    'Cambios guardados',
                    'La configuración del proyecto se actualizó.',
                  );
                },
        ),
      ),
    );
  }

  Future<void> _editRole(BuildContext context, ProjectMember member) async {
    final field = TextEditingController(text: member.roleLabel ?? '');

    final role = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rol de ${member.name}'),
        content: TextField(
          controller: field,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Rol en el proyecto'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(field.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    field.dispose();
    if (role != null && role.isNotEmpty) {
      controller.updateMemberRole(member.id, role.toUpperCase());
    }
  }

  Future<void> _confirmRemove(
    BuildContext context,
    ProjectMember member,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Quitar a ${member.name}?'),
        content: const Text(
          'Se eliminará del equipo del proyecto. Esta acción no se puede '
          'deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) controller.removeMember(member.id);
  }

  Future<void> _changeCoLeader(BuildContext context) async {
    final candidates = controller.members
        .where((member) => !member.isCreator)
        .toList();

    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todavía no hay integrantes que puedan ser co-líder.'),
        ),
      );
      return;
    }

    final selected = await showModalBottomSheet<ProjectMember>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppTagChip(label: 'Elegir co-líder'),
            ),
            for (final member in candidates)
              ListTile(
                title: Text(member.name),
                subtitle: member.subtitle == null
                    ? null
                    : Text(member.subtitle!),
                trailing: member.isCoLeader ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(context).pop(member),
              ),
          ],
        ),
      ),
    );

    if (selected != null) controller.setCoLeader(selected.id);
  }
}
