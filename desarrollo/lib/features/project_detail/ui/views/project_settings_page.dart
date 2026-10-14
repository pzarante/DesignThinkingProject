import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_form_actions.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../profile/domain/models/user_profile.dart';
import '../../../profile/ui/viewmodels/user_search_controller.dart';
import '../../../project_applications/ui/viewmodels/applicants_controller.dart';
import '../../domain/models/project_member.dart';
import '../../domain/models/project_role.dart';
import '../viewmodels/project_settings_controller.dart';
import '../widgets/applications_list.dart';

import '../widgets/project_member_tile.dart';
import '../widgets/role_settings_tile.dart';

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
      appBar: AppBar(title: const Text('Editar proyecto')),
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
              onPressed: () => _addMember(context),
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

          const AppSectionHeader(title: 'Vacantes'),
          Obx(
            () => Column(
              children: [
                for (var i = 0; i < controller.openRoles.length; i++)
                  RoleSettingsTile(
                    role: controller.openRoles[i],
                    onEdit: () => _editVacancy(context, i),
                    onDelete: () => controller.removeRole(i),
                  ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _editVacancy(context, null),
              icon: const Icon(Icons.add),
              label: const Text('Agregar vacante'),
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

          if (controller.isCreator) ...[
            const AppSectionHeader(title: 'Zona de peligro'),
            Card(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.15),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Eliminar proyecto',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Esta acción archivará el proyecto de forma permanente. '
                      'Ya no se mostrará en el feed, ni en búsquedas ni en Mis Proyectos.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(color: theme.colorScheme.error),
                      ),
                      onPressed: controller.isSaving.value
                          ? null
                          : () => _confirmDelete(context),
                      icon: const Icon(Icons.delete_forever_outlined),
                      label: const Text('Eliminar este proyecto'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: Obx(
        () => AppFormActions(
          primaryLabel: 'Guardar cambios',
          onPrimary: controller.canSave
              ? () async {
                  final saved = await controller.save();
                  if (saved && mounted) {
                    Get.back();
                    showSuccessSnack(
                      'Cambios guardados',
                      message: 'La configuración del proyecto se actualizó.',
                    );
                  } else if (mounted) {
                    showErrorSnack(
                      'No se pudo guardar',
                      message:
                          controller.saveError ??
                          'Verifica los campos obligatorios y permisos.',
                    );
                  }
                }
              : null,
        ),
      ),
    );
  }

  Future<void> _addMember(BuildContext context) async {
    final userSearchController = Get.find<UserSearchController>();
    if (userSearchController.users.isEmpty) {
      await userSearchController.load();
      if (!context.mounted) return;
    }
    final existingUserIds = controller.members.map((m) => m.id).toSet();
    final availableUsers = userSearchController.users
        .where((u) => !existingUserIds.contains(u.userId))
        .toList();

    if (availableUsers.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No hay más usuarios registrados disponibles para agregar.',
            ),
          ),
        );
      }
      return;
    }

    final roles = controller.assignableRoles;
    UserSummary? selectedUser = availableUsers.first;
    ProjectRole? selectedRole;

    final added = await showDialog<ProjectMember>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Agregar integrante'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seleccionar usuario',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                DropdownButtonFormField<UserSummary>(
                  initialValue: selectedUser,
                  isExpanded: true,
                  items: [
                    for (final user in availableUsers)
                      DropdownMenuItem(
                        value: user,
                        child: Text(
                          user.fullName?.isNotEmpty == true
                              ? '${user.fullName} (@${user.userName})'
                              : user.userName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (val) => setDialogState(() => selectedUser = val),
                ),
                const SizedBox(height: AppSpacing.md),
                _RolePicker(
                  roles: roles,
                  value: selectedRole,
                  onChanged: (role) =>
                      setDialogState(() => selectedRole = role),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (selectedUser == null) return;
                final role = selectedRole;
                final member = ProjectMember(
                  id: selectedUser!.userId,
                  name: selectedUser!.displayName,
                  avatarUrl: selectedUser!.avatarUrl,
                  projectRoleId: role == null
                      ? null
                      : controller.freeSlotOf(role),
                  roleLabel: role?.title.toUpperCase(),
                  subtitle: role?.title ?? (selectedUser!.career ?? ''),
                );
                Navigator.of(context).pop(member);
              },
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );

    if (added != null) {
      controller.addMember(added);
      if (mounted) {
        showSuccessSnack(
          'Integrante agregado',
          message: '${added.name} se sumó al equipo.',
        );
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar proyecto?'),
        content: const Text(
          'Esta acción archivará el proyecto de forma permanente y '
          'no se mostrará más en el feed. ¿Estás seguro de continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await controller.deleteProject();
      if (success) {
        Get.until(
          (route) => route.settings.name == AppRoutes.home || route.isFirst,
        );
        showSuccessSnack(
          'Proyecto eliminado',
          message: 'El proyecto fue archivado correctamente.',
        );
      } else {
        showErrorSnack('Error', message: 'No se pudo eliminar el proyecto.');
      }
    }
  }

  Future<void> _editRole(BuildContext context, ProjectMember member) async {
    final roles = controller.assignableRoles;
    if (roles.isEmpty) {
      showErrorSnack(
        'Sin vacantes libres',
        message: 'Agrega cupos a un rol para poder asignarlo.',
      );
      return;
    }
    ProjectRole? selected;

    final role = await showDialog<ProjectRole>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Rol de ${member.name}'),
          content: _RolePicker(
            roles: roles,
            value: selected,
            allowNone: false,
            onChanged: (role) => setDialogState(() => selected = role),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: selected == null
                  ? null
                  : () => Navigator.of(context).pop(selected),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (role != null) controller.updateMemberRole(member.id, role);
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

    final selection = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Co-liderazgo del proyecto'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop('none'),
            child: const Row(
              children: [
                Icon(Icons.remove_circle_outline, color: Colors.grey),
                SizedBox(width: AppSpacing.sm),
                Text('Dejar sin co-líder'),
              ],
            ),
          ),
          const Divider(),
          for (final member in candidates)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(member.id),
              child: Row(
                children: [
                  Icon(
                    member.isCoLeader
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: member.isCoLeader
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(member.name)),
                ],
              ),
            ),
        ],
      ),
    );

    if (selection == 'none') {
      controller.setCoLeader(null);
    } else if (selection != null) {
      controller.setCoLeader(selection);
    }
  }

  Future<void> _editVacancy(BuildContext context, int? index) async {
    final existing = index == null ? null : controller.openRoles[index];
    final titleField = TextEditingController(text: existing?.title ?? '');
    final descriptionField = TextEditingController(
      text: existing?.description ?? '',
    );
    final skillsField = TextEditingController(
      text: existing?.skills.join(', ') ?? '',
    );
    var totalSlots = existing?.totalSlots ?? 1;
    final minSlots = existing?.filledSlots ?? 0;

    final result = await showDialog<ProjectRole>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Nueva vacante' : 'Editar vacante'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleField,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Rol buscado'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: descriptionField,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Qué haría en el proyecto',
                    hintText: 'Breve descripción de las responsabilidades',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: skillsField,
                  decoration: const InputDecoration(
                    labelText: 'Habilidades (separadas por coma)',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Cupos', style: Theme.of(context).textTheme.labelMedium),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: totalSlots > minSlots && totalSlots > 1
                          ? () => setDialogState(() => totalSlots--)
                          : null,
                    ),
                    Text(
                      '$totalSlots',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => setDialogState(() => totalSlots++),
                    ),
                  ],
                ),
                if (minSlots > 0)
                  Text(
                    'Ya hay $minSlots cupo(s) ocupado(s); no puedes bajar de '
                    'ese número.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final title = titleField.text.trim();
                if (title.isEmpty) return;
                final skills = skillsField.text
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();

                Navigator.of(context).pop(
                  ProjectRole(
                    title: title,
                    description: descriptionField.text.trim().isEmpty
                        ? null
                        : descriptionField.text.trim(),
                    skills: skills,
                    totalSlots: totalSlots,
                    filledSlots: minSlots,
                    // Los cupos ya guardados siguen siendo los mismos: sin
                    // esto, renombrar el rol borraría sus filas y crearía
                    // otras nuevas.
                    slotIds: existing?.slotIds ?? const [],
                    openSlotIds: existing?.openSlotIds ?? const [],
                  ),
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      titleField.dispose();
      descriptionField.dispose();
      skillsField.dispose();
    });

    if (result == null) return;
    if (index == null) {
      controller.addRole(result);
    } else {
      controller.updateRole(index, result);
    }
  }
}

/// Elige el rol entre las vacantes con cupo libre: el rol de un integrante
/// es el cupo que ocupa en `project_roles`, no un texto aparte.
class _RolePicker extends StatelessWidget {
  const _RolePicker({
    required this.roles,
    required this.value,
    required this.onChanged,
    this.allowNone = true,
  });

  final List<ProjectRole> roles;
  final ProjectRole? value;
  final ValueChanged<ProjectRole?> onChanged;
  final bool allowNone;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<ProjectRole>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Rol en el proyecto',
        helperText: roles.isEmpty ? 'No hay vacantes con cupo libre.' : null,
      ),
      items: [
        if (allowNone)
          const DropdownMenuItem<ProjectRole>(child: Text('Sin rol')),
        for (final role in roles)
          DropdownMenuItem(value: role, child: Text(role.title)),
      ],
      onChanged: onChanged,
    );
  }
}
