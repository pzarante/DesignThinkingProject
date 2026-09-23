import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../domain/models/publication.dart';

/// Pestaña "Publicaciones".
///
/// El muro del proyecto es una feature aparte: aquí solo queda el hueco y,
/// para el equipo, el punto de entrada a crear la primera publicación.
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (canPublish)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Nueva publicación'),
            ),
          ),
        for (final publication in publications)
          Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(publication.authorName, style: Theme.of(context).textTheme.labelMedium),
                  Align(
                    alignment: Alignment.topRight,
                    child: PopupMenuButton<String>(
                      tooltip: 'Acciones de publicación',
                      onSelected: (action) => action == 'edit'
                          ? onEdit(publication)
                          : onDelete(publication),
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Editar')),
                        PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(publication.title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(publication.content),
                  if (publication.imageUrl != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.xs),
                      child: Image.network(
                        publication.imageUrl!,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                  ],
                  const Divider(height: AppSpacing.lg),
                  Row(
                    children: [
                      IconButton(
                        tooltip: publication.viewerReacted
                            ? 'Quitar reacción'
                            : 'Reaccionar',
                        onPressed: () => onReact(publication),
                        icon: Icon(
                          publication.viewerReacted
                              ? Icons.favorite
                              : Icons.favorite_border,
                        ),
                      ),
                      Text('${publication.reactionCount}'),
                      const SizedBox(width: AppSpacing.md),
                      IconButton(
                        tooltip: 'Comentar',
                        onPressed: () => onComment(publication),
                        icon: const Icon(Icons.chat_bubble_outline),
                      ),
                      Text('${publication.commentCount}'),
                    ],
                  ),
                  if (publication.comments.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    for (final comment in publication.comments)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Text(
                          comment,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}
