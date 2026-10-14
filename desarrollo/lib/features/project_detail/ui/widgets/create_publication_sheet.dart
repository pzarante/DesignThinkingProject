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
    builder: (context) =>
        _CreatePublicationSheet(projectId: projectId, authorName: authorName),
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
  State<_CreatePublicationSheet> createState() =>
      _CreatePublicationSheetState();
}

class _CreatePublicationSheetState extends State<_CreatePublicationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _imageController = TextEditingController();
  final _linkController = TextEditingController();
  final _pollOptionControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  String _contentType = 'text';

  @override
  void initState() {
    super.initState();
    final publication = widget.initialPublication;
    if (publication != null) {
      _titleController.text = publication.title;
      _contentController.text = publication.content;
      _imageController.text = publication.imageUrl ?? '';
      _linkController.text = publication.linkUrl ?? '';
      _contentType = publication.pollOptions.isNotEmpty
          ? 'poll'
          : publication.linkUrl != null
          ? 'link'
          : 'text';
      for (var i = 0; i < publication.pollOptions.length && i < 4; i++) {
        _pollOptionControllers[i].text = publication.pollOptions[i];
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _imageController.dispose();
    _linkController.dispose();
    for (final controller in _pollOptionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _isEditing => widget.initialPublication != null;

  void _publish() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop(
      Publication(
        id:
            widget.initialPublication?.id ??
            'publication-${DateTime.now().microsecondsSinceEpoch}',
        projectId: widget.projectId,
        authorName: widget.authorName,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        imageUrl: _imageController.text.trim().isEmpty
            ? null
            : _imageController.text.trim(),
        linkUrl: _contentType == 'link' ? _linkController.text.trim() : null,
        pollOptions: _isEditing && _contentType == 'poll'
            ? widget.initialPublication!.pollOptions
            : _contentType == 'poll'
            ? _pollOptionControllers
                  .map((controller) => controller.text.trim())
                  .where((option) => option.isNotEmpty)
                  .toList()
            : const [],
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
              Text(
                '¿Qué quieres compartir?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'text', label: Text('Texto')),
                  ButtonSegment(value: 'link', label: Text('Link')),
                  ButtonSegment(value: 'poll', label: Text('Encuesta')),
                ],
                selected: {_contentType},
                // Al editar no cambia: un avance y una encuesta son tablas
                // distintas en ROBLE.
                onSelectionChanged: _isEditing
                    ? null
                    : (selection) =>
                          setState(() => _contentType = selection.first),
              ),
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
              if (_contentType == 'link') ...[
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _linkController,
                  label: 'Enlace',
                  isRequired: true,
                  keyboardType: TextInputType.url,
                  hintText: 'https://...',
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return 'Pega un enlace.';
                    final uri = Uri.tryParse(text);
                    return uri?.hasScheme == true
                        ? null
                        : 'Usa un enlace válido.';
                  },
                ),
              ],
              if (_contentType == 'poll' && _isEditing) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Opciones: ${widget.initialPublication!.pollOptions.join(' · ')}',
                ),
                Text(
                  'No se pueden cambiar: la encuesta ya puede tener votos.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (_contentType == 'poll' && !_isEditing) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Opciones de respuesta',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                for (var i = 0; i < 4; i++) ...[
                  AppTextField(
                    controller: _pollOptionControllers[i],
                    label: 'Opción ${i + 1}${i < 2 ? ' *' : ''}',
                    isRequired: i < 2,
                    validator: (value) =>
                        i < 2 && (value == null || value.trim().isEmpty)
                        ? 'Agrega al menos dos opciones.'
                        : null,
                  ),
                  if (i < 3) const SizedBox(height: AppSpacing.sm),
                ],
              ],
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
                    widget.initialPublication == null
                        ? 'Publicar'
                        : 'Guardar cambios',
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
