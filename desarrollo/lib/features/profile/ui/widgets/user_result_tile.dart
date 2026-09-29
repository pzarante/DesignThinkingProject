import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../domain/models/user_profile.dart';

/// Una persona en la lista de resultados de Explorar.
///
/// Lo que manda en la fila es el `user_name` —es lo que se busca—, con el
/// nombre real debajo como apoyo.
class UserResultTile extends StatelessWidget {
  const UserResultTile({super.key, required this.user, required this.onTap});

  final UserSummary user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final subtitle = [
      if (user.fullName != null && user.fullName!.trim().isNotEmpty)
        user.fullName!.trim(),
      if (user.career != null && user.career!.trim().isNotEmpty)
        user.career!.trim(),
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        leading: AppAvatar(
          name: user.displayName,
          avatarUrl: user.avatarUrl,
          size: 44,
        ),
        title: Text(
          '@${user.userName}',
          style: theme.textTheme.titleMedium,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: subtitle.isEmpty
            ? null
            : Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
        trailing: Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
      ),
    );
  }
}
