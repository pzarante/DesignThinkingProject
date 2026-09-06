import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Title that opens a content section inside a scrollable screen.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}
