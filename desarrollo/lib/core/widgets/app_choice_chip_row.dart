import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Horizontally scrollable row of single-select chips (e.g. type or
/// category filters). Uses [FilterChip], which already themes itself from
/// [ColorScheme] — no literal colors needed here.
class AppChoiceChipRow<T> extends StatelessWidget {
  const AppChoiceChipRow({
    super.key,
    required this.options,
    required this.labelBuilder,
    required this.selected,
    required this.onSelected,
  });

  final List<T> options;
  final String Function(T option) labelBuilder;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final option in options)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: FilterChip(
                label: Text(labelBuilder(option)),
                selected: option == selected,
                onSelected: (_) => onSelected(option),
              ),
            ),
        ],
      ),
    );
  }
}
