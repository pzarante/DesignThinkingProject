import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../domain/models/project_detail.dart';
import 'project_member_tile.dart';
import 'project_role_card.dart';

/// Pestaña "Equipo": quién está dentro y qué roles siguen abiertos.
class TeamTab extends StatelessWidget {
  const TeamTab({super.key, required this.detail});

  final ProjectDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final counter = detail.maxMembers == 0
        ? '${detail.members.length}'
        : '${detail.members.length}/${detail.maxMembers}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(title: 'Integrantes ($counter)'),
        if (detail.members.isEmpty)
          Text(
            'El equipo todavía no tiene integrantes registrados.',
            style: theme.textTheme.bodyMedium,
          )
        else
          for (final member in detail.members)
            ProjectMemberTile(member: member),
        if (detail.availability != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Dedicación esperada: ${detail.availability}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const AppSectionHeader(title: 'Roles buscados'),
        if (detail.openRoles.isEmpty)
          Text(
            'Este proyecto no tiene roles abiertos por ahora.',
            style: theme.textTheme.bodyMedium,
          )
        else
          for (final role in detail.openRoles) ProjectRoleCard(role: role),
      ],
    );
  }
}
