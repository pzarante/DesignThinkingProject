import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../domain/models/person.dart';
import '../viewmodels/project_creation_controller.dart';

/// Paso 5: roles buscados, tamaño del equipo, disponibilidad y co-líder.
class TeamStep extends StatefulWidget {
  const TeamStep({super.key, required this.controller});

  final ProjectCreationController controller;

  @override
  State<TeamStep> createState() => _TeamStepState();
}

class _TeamStepState extends State<TeamStep> {
  final TextEditingController _personQuery = TextEditingController();
  String _query = '';

  ProjectCreationController get controller => widget.controller;

  @override
  void dispose() {
    _personQuery.dispose();
    super.dispose();
  }

  Future<void> _addRole() async {
    final role = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _RolePickerSheet(
        suggestions: controller.options.roleSuggestions
            .where((role) => !controller.roles.contains(role))
            .toList(),
      ),
    );
    if (role != null) controller.addRole(role);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Roles necesarios', style: theme.textTheme.labelMedium),
        const SizedBox(height: AppSpacing.xs),
        Obx(
          () => Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final role in controller.roles)
                InputChip(
                  label: Text(role),
                  onDeleted: () => controller.removeRole(role),
                ),
              ActionChip(
                avatar: const Icon(Icons.add, size: 18),
                label: const Text('Agregar rol'),
                onPressed: _addRole,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Máximo de integrantes', style: theme.textTheme.labelMedium),
        const SizedBox(height: AppSpacing.xs),
        Obx(
          () => Row(
            children: [
              IconButton.outlined(
                onPressed: controller.decreaseMembers,
                icon: const Icon(Icons.remove),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                ),
                child: Text(
                  '${controller.maxMembers.value}',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              IconButton.filledTonal(
                onPressed: controller.increaseMembers,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Disponibilidad requerida', style: theme.textTheme.labelMedium),
        const SizedBox(height: AppSpacing.xs),
        Obx(() {
          final availabilityOptions = controller.options.availabilityOptions;
          // Los catálogos se cargan de forma asíncrona; sin opciones no hay
          // control que mostrar todavía.
          if (availabilityOptions.isEmpty) return const SizedBox.shrink();

          return SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [
              for (final option in availabilityOptions)
                ButtonSegment<String>(value: option, label: Text(option)),
            ],
            selected: {controller.availability.value},
            onSelectionChanged: (selection) =>
                controller.setAvailability(selection.first),
          );
        }),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Co-líder de proyecto (opcional)',
          style: theme.textTheme.labelMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Selecciona a una persona como co-líder o asígnalo más tarde en la '
          'configuración del proyecto.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _personQuery,
          onChanged: (value) => setState(() => _query = value),
          decoration: const InputDecoration(
            hintText: 'Buscar persona...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Obx(() {
          final candidates = controller.candidatesMatching(_query);
          final selected = controller.coLeader.value;

          if (candidates.isEmpty) {
            return Text(
              'Nadie coincide con la búsqueda.',
              style: theme.textTheme.bodySmall,
            );
          }

          return Column(
            children: [
              for (final person in candidates)
                _CandidateTile(
                  person: person,
                  isSelected: selected?.id == person.id,
                  onPressed: () => controller.toggleCoLeader(person),
                ),
            ],
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: controller.clearCoLeader,
            child: const Text('Asignar después'),
          ),
        ),
        Text(
          'El co-líder puede gestionar el proyecto junto al creador.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _CandidateTile extends StatelessWidget {
  const _CandidateTile({
    required this.person,
    required this.isSelected,
    required this.onPressed,
  });

  final Person person;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: AppAvatar(name: person.name),
        title: Text(person.name),
        trailing: isSelected
            ? FilledButton.tonal(
                onPressed: onPressed,
                child: const Text('Seleccionado'),
              )
            : FilledButton(
                onPressed: onPressed,
                child: const Text('Seleccionar'),
              ),
      ),
    );
  }
}

/// Hoja para elegir un rol sugerido o escribir uno nuevo.
class _RolePickerSheet extends StatefulWidget {
  const _RolePickerSheet({required this.suggestions});

  final List<String> suggestions;

  @override
  State<_RolePickerSheet> createState() => _RolePickerSheetState();
}

class _RolePickerSheetState extends State<_RolePickerSheet> {
  final TextEditingController _customRole = TextEditingController();

  @override
  void dispose() {
    _customRole.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Agregar rol',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final role in widget.suggestions)
                ActionChip(
                  label: Text(role),
                  onPressed: () => Navigator.of(context).pop(role),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _customRole,
            autofocus: widget.suggestions.isEmpty,
            onSubmitted: (value) => Navigator.of(context).pop(value),
            decoration: InputDecoration(
              hintText: 'Otro rol...',
              suffixIcon: IconButton(
                icon: const Icon(Icons.check),
                onPressed: () => Navigator.of(context).pop(_customRole.text),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
