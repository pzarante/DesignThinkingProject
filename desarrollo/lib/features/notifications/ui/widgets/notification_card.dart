import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_icon_badge.dart';
import '../../domain/models/app_notification.dart';

/// Una notificación: icono a la izquierda, título y hora en la misma línea,
/// mensaje debajo. Sin leer se ve resaltada y con un punto junto a la hora.
class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final unread = !notification.isRead;
    final tone = _toneFor(notification.type, colors);
    const radius = BorderRadius.all(Radius.circular(AppSpacing.md - 4));

    return Material(
      color: unread
          ? colors.primaryContainer.withValues(alpha: 0.35)
          : Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIconBadge(
                icon: _iconFor(notification.type),
                backgroundColor: tone.withValues(alpha: 0.14),
                iconColor: tone,
              ),
              const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: unread
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          _timeAgo(notification.createdAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        if (unread) ...[
                          const SizedBox(width: AppSpacing.xs + 2),
                          Container(
                            width: AppSpacing.sm,
                            height: AppSpacing.sm,
                            decoration: BoxDecoration(
                              color: colors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      notification.message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: unread
                            ? colors.onSurface
                            : colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(NotificationType type) => switch (type) {
    NotificationType.applicationReceived => Icons.person_add_alt_1_outlined,
    NotificationType.applicationAccepted => Icons.check_circle_outline,
    NotificationType.applicationRejected => Icons.highlight_off,
    NotificationType.memberLeft => Icons.logout_outlined,
    NotificationType.projectComment => Icons.chat_bubble_outline,
    NotificationType.projectUpdate => Icons.campaign_outlined,
    NotificationType.pollActivity => Icons.poll_outlined,
  };

  Color _toneFor(NotificationType type, ColorScheme colors) => switch (type) {
    NotificationType.applicationRejected => colors.error,
    NotificationType.applicationReceived => colors.tertiary,
    NotificationType.memberLeft ||
    NotificationType.projectComment => colors.secondary,
    _ => colors.primary,
  };

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} d';
    return '${date.day}/${date.month}/${date.year}';
  }
}
