import 'package:flutter/material.dart';

import '../../../../core/app_keys.dart';

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
          key: AppKeys.projectLeaveConfirmButton,
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
