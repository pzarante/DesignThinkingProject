import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Editor de etiquetas: muestra las ya elegidas, deja buscar entre las
/// sugeridas y crear una nueva con lo que se escriba.
///
/// La lista de seleccionadas la posee quien llama (el controller); este
/// widget solo reporta altas y bajas y guarda el texto de búsqueda.
class AppTagInput extends StatefulWidget {
  const AppTagInput({
    super.key,
    required this.selectedTags,
    required this.onAdd,
    required this.onRemove,
    this.systemTags = const [],
    this.communityTags = const [],
    this.hintText = 'Escribe para buscar o crear tag...',
    this.showSuggestions = true,
  });

  final List<String> selectedTags;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  /// Etiquetas propuestas por la plataforma (icono de escudo en el diseño).
  final List<String> systemTags;

  /// Etiquetas que ya usan otras comunidades (icono de personas).
  final List<String> communityTags;
  final String hintText;

  /// El formulario de comunidad muestra solo el buscador, sin el panel de
  /// sugerencias desplegado.
  final bool showSuggestions;

  @override
  State<AppTagInput> createState() => _AppTagInputState();
}

class _AppTagInputState extends State<AppTagInput> {
  final TextEditingController _queryController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _add(String tag) {
    final clean = tag.trim().replaceAll('#', '');
    if (clean.isEmpty) return;
    if (!widget.selectedTags.contains(clean)) widget.onAdd(clean);
    _queryController.clear();
    setState(() => _query = '');
  }

  List<String> _filter(List<String> source) {
    return source
        .where(
          (tag) =>
              !widget.selectedTags.contains(tag) &&
              tag.toLowerCase().contains(_query.trim().toLowerCase()),
        )
        .toList();
  }

  bool get _canCreate {
    final clean = _query.trim().replaceAll('#', '');
    if (clean.isEmpty) return false;
    final known = [...widget.systemTags, ...widget.communityTags];
    return !known.any((tag) => tag.toLowerCase() == clean.toLowerCase()) &&
        !widget.selectedTags.any((tag) => tag.toLowerCase() == clean.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final systemMatches = _filter(widget.systemTags);
    final communityMatches = _filter(widget.communityTags);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.selectedTags.isNotEmpty)
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final tag in widget.selectedTags)
                InputChip(
                  label: Text('#$tag'),
                  onDeleted: () => widget.onRemove(tag),
                ),
            ],
          ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _queryController,
          onChanged: (value) => setState(() => _query = value),
          onSubmitted: _add,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: const Icon(Icons.search),
          ),
        ),
        if (widget.showSuggestions) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (systemMatches.isNotEmpty)
                  _SuggestionGroup(
                    title: 'Tags del sistema',
                    icon: Icons.verified_user_outlined,
                    tags: systemMatches,
                    onSelected: _add,
                  ),
                if (communityMatches.isNotEmpty)
                  _SuggestionGroup(
                    title: 'Tags de la comunidad',
                    icon: Icons.groups_outlined,
                    tags: communityMatches,
                    onSelected: _add,
                  ),
                if (_canCreate)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.add),
                    title: Text('Crear tag "#${_query.trim()}"'),
                    onTap: () => _add(_query),
                  ),
                if (systemMatches.isEmpty &&
                    communityMatches.isEmpty &&
                    !_canCreate)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Text(
                      'No hay más sugerencias.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SuggestionGroup extends StatelessWidget {
  const _SuggestionGroup({
    required this.title,
    required this.icon,
    required this.tags,
    required this.onSelected,
  });

  final String title;
  final IconData icon;
  final List<String> tags;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Text(title, style: theme.textTheme.labelMedium),
        ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            for (final tag in tags)
              ActionChip(
                avatar: Icon(icon, size: 16),
                label: Text('#$tag'),
                onPressed: () => onSelected(tag),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
      ],
    );
  }
}
