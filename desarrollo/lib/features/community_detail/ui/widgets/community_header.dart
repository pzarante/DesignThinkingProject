import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_community_cover.dart';
import '../../domain/models/community_detail.dart';

/// Portada, nombre, descripción y el botón de seguir.
class CommunityHeader extends StatelessWidget {
  const CommunityHeader({
    super.key,
    required this.community,
    required this.onToggleMembership,
  });

  final CommunityDetail community;
  final VoidCallback onToggleMembership;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCommunityCover(
          communityId: community.id,
          communityName: community.name,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(community.name, style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Icon(
                    Icons.groups_outlined,
                    size: 18,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    community.memberCount == 1
                        ? '1 miembro'
                        : '${community.memberCount} miembros',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (community.description != null &&
                  community.description!.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  community.description!.trim(),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                // Quien la creó siempre es miembro: el botón se lo dice en
                // vez de ofrecerle salir de su propia comunidad.
                child: community.isOwner
                    ? OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.verified_outlined),
                        label: const Text('Tu comunidad'),
                      )
                    : community.isMember
                    ? OutlinedButton.icon(
                        onPressed: onToggleMembership,
                        icon: const Icon(Icons.check),
                        label: const Text('Siguiendo'),
                      )
                    : FilledButton.icon(
                        onPressed: onToggleMembership,
                        icon: const Icon(Icons.add),
                        label: const Text('Seguir comunidad'),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
