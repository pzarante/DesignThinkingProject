import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_tag_chip.dart';
import '../../domain/models/project_member.dart';

/// Fila de un integrante del equipo.
class ProjectMemberTile extends StatelessWidget {
  const ProjectMemberTile({super.key, required this.member, this.trailing});

  final ProjectMember member;

  /// Acciones de la fila en la pantalla de configuración; null en el detalle.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: ListTile(
        leading: AppAvatar(name: member.name),
        title: Row(
          children: [
            Flexible(
              child: Text(member.name, style: theme.textTheme.titleSmall),
            ),
            if (member.roleLabel != null) ...[
              const SizedBox(width: AppSpacing.sm),
              AppTagChip(label: member.roleLabel!),
            ],
          ],
        ),
        subtitle: member.subtitle == null ? null : Text(member.subtitle!),
        trailing: trailing,
      ),
    );
  }
}
