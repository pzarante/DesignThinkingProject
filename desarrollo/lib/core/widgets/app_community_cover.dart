import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Portada de comunidad basada en color, sin imágenes remotas.
class AppCommunityCover extends StatelessWidget {
  const AppCommunityCover({
    super.key,
    required this.communityId,
    required this.communityName,
  });

  final String communityId;
  final String communityName;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final palette = [
      colors.primary,
      colors.secondary,
      colors.tertiary,
      colors.primaryContainer,
    ];
    final index = communityId.codeUnits.fold<int>(
      0,
      (sum, code) => sum + code,
    );
    final background = palette[index % palette.length];
    final foreground = ThemeData.estimateBrightnessForColor(background) ==
            Brightness.dark
        ? Colors.white
        : colors.onSurface;

    return AspectRatio(
      aspectRatio: 16 / 7,
      child: Container(
        width: double.infinity,
        color: background,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_outlined, color: foreground, size: 38),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _initials(communityName),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
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
