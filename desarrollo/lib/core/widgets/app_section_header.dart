import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Title that opens a content section inside a scrollable screen.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Sin sangría lateral: el título tiene que empezar en el mismo borde
      // que las tarjetas que encabeza, y esos 4 px lo dejaban descuadrado.
      padding: const EdgeInsets.only(
        top: AppSpacing.lg,
        bottom: AppSpacing.sm,
      ),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}
