import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../domain/models/publication.dart';

/// Pestaña "Publicaciones": el muro del proyecto.
class PostsTab extends StatelessWidget {
  const PostsTab({
    super.key,
    required this.canPublish,
    required this.onCreate,
    required this.publications,
    required this.onEdit,
    required this.onDelete,
    required this.onReact,
    required this.onComment,
  });

  final bool canPublish;
  final VoidCallback onCreate;
  final List<Publication> publications;
  final ValueChanged<Publication> onEdit;
  final ValueChanged<Publication> onDelete;
  final ValueChanged<Publication> onReact;
  final ValueChanged<Publication> onComment;

  @override
  Widget build(BuildContext context) {
    if (publications.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: AppEmptyState(
          icon: Icons.forum_outlined,
          title: 'Aún no hay publicaciones',
          message: canPublish
              ? 'Comparte avances, prototipos o preguntas con quienes siguen '
                    'el proyecto.'
              : 'Cuando el equipo publique algo, aparecerá aquí.',
          action: canPublish
              ? FilledButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add),
                  label: const Text('Crear publicación'),
                )
              : null,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canPublish)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: OutlinedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Nueva publicación'),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        for (final publication in publications)
          _PublicationCard(
            publication: publication,
            canManage: canPublish,
            onEdit: () => onEdit(publication),
            onDelete: () => onDelete(publication),
            onReact: () => onReact(publication),
            onComment: () => onComment(publication),
          ),
      ],
    );
  }
}

/// Una publicación del muro.
///
/// El encabezado es una fila: avatar, autor y fecha a la izquierda, menú a la
/// derecha, todo centrado sobre la misma línea. Antes el menú iba debajo del
/// nombre, alineado a la derecha por su cuenta, y quedaba descolgado del
/// resto de la tarjeta.
class _PublicationCard extends StatelessWidget {
  const _PublicationCard({
    required this.publication,
    required this.canManage,
    required this.onEdit,
    required this.onDelete,
    required this.onReact,
    required this.onComment,
  });

  final Publication publication;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReact;
  final VoidCallback onComment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppAvatar(name: publication.authorName, size: 36),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        publication.authorName,
                        style: theme.textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (publication.createdAt != null)
                        Text(
                          _relativeDate(publication.createdAt!),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                // Editar y eliminar son del equipo; un visitante no debería
                // ver siquiera el menú.
                if (canManage)
                  PopupMenuButton<String>(
                    tooltip: 'Acciones de publicación',
                    onSelected: (action) =>
                        action == 'edit' ? onEdit() : onDelete(),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(publication.title, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(publication.content, style: theme.textTheme.bodyMedium),
            if (publication.imageUrl != null) ...[
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.sm),
                child: Image.network(
                  publication.imageUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ],
            const Divider(height: AppSpacing.lg),
            Row(
              children: [
                _ActionButton(
                  icon: publication.viewerReacted
                      ? Icons.favorite
                      : Icons.favorite_border,
                  label: '${publication.reactionCount}',
                  tooltip: publication.viewerReacted
                      ? 'Quitar reacción'
                      : 'Reaccionar',
                  highlighted: publication.viewerReacted,
                  onPressed: onReact,
                ),
                const SizedBox(width: AppSpacing.sm),
                _ActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: '${publication.commentCount}',
                  tooltip: 'Comentar',
                  onPressed: onComment,
                ),
              ],
            ),
            if (publication.comments.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              for (final comment in publication.comments)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.subdirectory_arrow_right,
                        size: 14,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          comment,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  /// "hace 3 días". Sin `intl`: el proyecto no lo usa y para esto no compensa.
  String _relativeDate(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'Ahora mismo';
    if (difference.inHours < 1) return 'hace ${difference.inMinutes} min';
    if (difference.inDays < 1) return 'hace ${difference.inHours} h';
    if (difference.inDays == 1) return 'ayer';
    if (difference.inDays < 30) return 'hace ${difference.inDays} días';
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Icono y número como un solo control, en vez de un [IconButton] con un
/// [Text] suelto al lado: así el número queda centrado con el icono y el área
/// que se puede tocar los incluye a los dos.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onPressed,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback onPressed;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = highlighted ? colors.primary : colors.onSurfaceVariant;

    return Tooltip(
      message: tooltip,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: TextButton.styleFrom(
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
