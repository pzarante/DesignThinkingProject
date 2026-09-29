import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/models/project_member.dart';

/// Pide a quien lidera que elija quién queda a cargo antes de salir.
///
/// Devuelve el id del elegido, o null si canceló.
Future<String?> showPickNewLeaderDialog(
  BuildContext context, {
  required List<ProjectMember> candidates,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _PickNewLeaderDialog(candidates: candidates),
  );
}

/// Avisa que no se puede salir: quien lidera no tiene a quién dejarle el
/// proyecto.
Future<void> showCannotLeaveDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.group_off_outlined),
      title: const Text('Aún no puedes salir'),
      content: const Text(
        'Lideras este proyecto y no hay nadie más en el equipo para '
        'dejarlo a cargo. Acepta a alguien en una vacante primero.',
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Entendido'),
        ),
      ],
    ),
  );
}

/// Confirmación final antes de salir. True si confirmó.
Future<bool> showConfirmLeaveDialog(
  BuildContext context, {
  required String projectName,
  String? newLeaderName,
}) async {
  final colors = Theme.of(context).colorScheme;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: Icon(Icons.logout, color: colors.error),
      title: const Text('¿Estás seguro?'),
      content: Text(
        [
          'Vas a salir de $projectName. Dejarás de ver sus herramientas de '
              'equipo y tu cupo quedará libre para otra persona.',
          if (newLeaderName != null) '$newLeaderName pasará a liderarlo.',
          'Para volver tendrás que postularte de nuevo.',
        ].join('\n\n'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: colors.error,
            foregroundColor: colors.onError,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Salir del proyecto'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

class _PickNewLeaderDialog extends StatefulWidget {
  const _PickNewLeaderDialog({required this.candidates});

  final List<ProjectMember> candidates;

  @override
  State<_PickNewLeaderDialog> createState() => _PickNewLeaderDialogState();
}

class _PickNewLeaderDialogState extends State<_PickNewLeaderDialog> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Elige al nuevo líder'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lideras este proyecto. Antes de salir, elige quién quedará '
              'a cargo.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Flexible(
              child: RadioGroup<String>(
                groupValue: _selectedId,
                onChanged: (id) => setState(() => _selectedId = id),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final member in widget.candidates)
                      RadioListTile<String>(
                        value: member.id,
                        contentPadding: EdgeInsets.zero,
                        title: Text(member.name),
                        subtitle: member.roleLabel == null
                            ? null
                            : Text(member.roleLabel!),
                      ),
                  ],
                ),
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
          onPressed: _selectedId == null
              ? null
              : () => Navigator.of(context).pop(_selectedId),
          child: const Text('Continuar'),
        ),
      ],
    );
  }
}
