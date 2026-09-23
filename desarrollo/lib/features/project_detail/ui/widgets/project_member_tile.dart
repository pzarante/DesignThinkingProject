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
        leading: AppAvatar(name: member.name, avatarUrl: member.avatarUrl),
        title: Text(
          member.name,
          style: theme.textTheme.titleSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (member.roleLabel != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: Alignment.centerLeft,
                child: AppTagChip(label: member.roleLabel!),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
            if (member.subtitle != null) Text(member.subtitle!),
          ],
        ),
        trailing: trailing,
      ),
    );
  }
}
