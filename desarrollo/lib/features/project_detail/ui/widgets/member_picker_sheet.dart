import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_tag_chip.dart';
import '../../domain/models/project_member.dart';

/// Hoja inferior para elegir a un integrante del equipo: el co-líder desde
/// la configuración, o el nuevo líder antes de salir del proyecto.
///
/// [isSelected] marca con un check a quien ya tiene ese papel; [isSuggested]
/// pone primero a quien conviene elegir y lo etiqueta como sugerido.
/// Devuelve el integrante elegido, o null si se cerró sin elegir.
Future<ProjectMember?> showMemberPickerSheet(
  BuildContext context, {
  required String label,
  required List<ProjectMember> candidates,
  bool Function(ProjectMember member)? isSelected,
  bool Function(ProjectMember member)? isSuggested,
}) {
  final suggested = isSuggested ?? (_) => false;
  final ordered = [
    ...candidates.where(suggested),
    ...candidates.where((member) => !suggested(member)),
  ];

  return showModalBottomSheet<ProjectMember>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppTagChip(label: label),
          ),
          for (final member in ordered)
            ListTile(
              title: Text(member.name),
              subtitle: member.subtitle == null
                  ? null
                  : Text(member.subtitle!),
              trailing: (isSelected?.call(member) ?? false)
                  ? const Icon(Icons.check)
                  : (suggested(member)
                        ? const AppTagChip(label: 'Sugerido')
                        : null),
              onTap: () => Navigator.of(context).pop(member),
            ),
        ],
      ),
    ),
  );
}
