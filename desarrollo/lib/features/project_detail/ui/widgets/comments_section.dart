import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../domain/models/project_comment.dart';

/// Comentarios públicos del proyecto.
///
/// Cualquiera con sesión puede escribir uno, incluida la de invitado: por
/// eso el campo nunca se deshabilita por falta de cuenta.
class CommentsSection extends StatefulWidget {
  const CommentsSection({
    super.key,
    required this.comments,
    required this.isSending,
    required this.onSubmit,
  });

  final List<ProjectComment> comments;
  final bool isSending;
  final ValueChanged<String> onSubmit;

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  final _field = TextEditingController();

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _field.text.trim();
    if (text.isEmpty) return;
    widget.onSubmit(text);
    _field.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(title: 'Comentarios (${widget.comments.length})'),
        if (widget.comments.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              'Sé el primero en comentar.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          for (final comment in widget.comments)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(comment.authorName, style: theme.textTheme.titleSmall),
                  Text(comment.content, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _field,
                decoration: const InputDecoration(
                  hintText: 'Escribe un comentario...',
                ),
                onSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            widget.isSending
                ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    onPressed: _submit,
                    icon: const Icon(Icons.send),
                    tooltip: 'Enviar comentario',
                  ),
          ],
        ),
      ],
    );
  }
}
