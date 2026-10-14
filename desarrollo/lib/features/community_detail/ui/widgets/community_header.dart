import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/models/community_detail.dart';

/// Portada, nombre, descripción y el botón de seguir.
class CommunityHeader extends StatelessWidget {
  const CommunityHeader({
    super.key,
    required this.community,
    required this.onToggleFollowing,
  });

  final CommunityDetail community;
  final VoidCallback onToggleFollowing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Cover(coverUrl: community.coverUrl),
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
                  Expanded(
                    child: Text(
                      '${community.memberCount == 1 ? '1 miembro' : '${community.memberCount} miembros'}'
                      ' · ${community.followerCount == 1 ? '1 seguidor' : '${community.followerCount} seguidores'}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
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
                // Quien la creó siempre la sigue: el botón se lo dice en
                // vez de ofrecerle salir de su propia comunidad.
                child: community.isOwner
                    ? OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.verified_outlined),
                        label: const Text('Tu comunidad'),
                      )
                    : community.isFollowing
                    ? OutlinedButton.icon(
                        onPressed: onToggleFollowing,
                        icon: const Icon(Icons.check),
                        label: const Text('Siguiendo'),
                      )
                    : FilledButton.icon(
                        onPressed: onToggleFollowing,
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

class _Cover extends StatelessWidget {
  const _Cover({this.coverUrl});

  final String? coverUrl;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final isValidUrl = coverUrl != null && coverUrl!.trim().isNotEmpty;

    if (!isValidUrl) {
      return Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.primary, colors.primaryContainer],
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.groups_outlined,
          color: colors.onPrimary.withValues(alpha: 0.5),
          size: 40,
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 16 / 7,
      child: Image.network(
        coverUrl!.trim(),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colors.primary, colors.primaryContainer],
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.groups_outlined,
            color: colors.onPrimary.withValues(alpha: 0.5),
            size: 40,
          ),
        ),
      ),
    );
  }
}
