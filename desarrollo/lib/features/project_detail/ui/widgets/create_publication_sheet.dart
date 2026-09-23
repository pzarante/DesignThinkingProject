import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/models/publication.dart';

Future<Publication?> showCreatePublicationSheet(
  BuildContext context, {
  required String projectId,
  required String authorName,
}) {
  return showModalBottomSheet<Publication>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _CreatePublicationSheet(
      projectId: projectId,
      authorName: authorName,
    ),
  );
}

Future<Publication?> showEditPublicationSheet(
  BuildContext context, {
  required Publication publication,
}) {
  return showModalBottomSheet<Publication>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _CreatePublicationSheet(
      projectId: publication.projectId,
      authorName: publication.authorName,
      initialPublication: publication,
    ),
  );
}

class _CreatePublicationSheet extends StatefulWidget {
  const _CreatePublicationSheet({
    required this.projectId,
    required this.authorName,
    this.initialPublication,
  });

  final String projectId;
  final String authorName;
  final Publication? initialPublication;

  @override
  State<_CreatePublicationSheet> createState() => _CreatePublicationSheetState();
}

class _CreatePublicationSheetState extends State<_CreatePublicationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _imageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final publication = widget.initialPublication;
    if (publication != null) {
      _titleController.text = publication.title;
      _contentController.text = publication.content;
      _imageController.text = publication.imageUrl ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  void _publish() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop(
      Publication(
        id: widget.initialPublication?.id ??
            'publication-${DateTime.now().microsecondsSinceEpoch}',
        projectId: widget.projectId,
        authorName: widget.authorName,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        imageUrl: _imageController.text.trim().isEmpty
            ? null
            : _imageController.text.trim(),
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.initialPublication == null
                        ? 'Nueva publicación'
                        : 'Editar publicación',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text('¿Qué quieres compartir?', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _titleController,
                label: 'Título de la publicación',
                isRequired: true,
                maxLength: 80,
                hintText: 'Ej. Avances del prototipo',
                validator: (value) => value == null || value.trim().isEmpty
                  ? 'Escribe un título.'
                  : null,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _contentController,
                label: 'Contenido',
                isRequired: true,
                minLines: 4,
                maxLines: 7,
                hintText: 'Comparte un avance, pregunta o recurso...',
                validator: (value) => value == null || value.trim().isEmpty
                  ? 'Escribe el contenido.'
                  : null,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _imageController,
                label: 'Imagen o recurso (opcional)',
                hintText: 'Pega una URL de imagen',
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _publish,
                  child: Text(
                    widget.initialPublication == null ? 'Publicar' : 'Guardar cambios',
                  ),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
