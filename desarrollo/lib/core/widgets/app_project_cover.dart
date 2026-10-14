import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Portada visual de un proyecto sin depender de una imagen remota.
///
/// El color se calcula con el identificador para que sea estable entre
/// pantallas y sesiones.
class AppProjectCover extends StatelessWidget {
  const AppProjectCover({
    super.key,
    required this.projectId,
    required this.projectName,
    this.isNew = false,
  });

  final String projectId;
  final String projectName;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final palette = [
      colors.primaryContainer,
      colors.secondaryContainer,
      colors.tertiaryContainer,
      colors.surfaceContainerHighest,
    ];
    final index = projectId.codeUnits.fold<int>(0, (sum, code) => sum + code);
    final background = palette[index % palette.length];
    final foreground = ThemeData.estimateBrightnessForColor(background) ==
            Brightness.dark
        ? Colors.white
        : colors.onSurface;

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            color: background,
            alignment: Alignment.center,
            child: Text(
              _initials(projectName),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (isNew)
            Positioned(
              top: AppSpacing.sm,
              left: AppSpacing.sm,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colors.tertiary,
                  borderRadius: BorderRadius.circular(AppSpacing.xs),
                ),
                child: Text(
                  'NUEVO',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onTertiary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _initials(String value) {
    final words = value.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty) return '?';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return '${words.first[0]}${words[1][0]}'.toUpperCase();
  }
}
