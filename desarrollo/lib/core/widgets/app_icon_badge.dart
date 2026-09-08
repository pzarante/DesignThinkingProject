import 'package:flutter/material.dart';

/// Rounded square that frames a leading icon in tiles and the app bar.
class AppIconBadge extends StatelessWidget {
  const AppIconBadge({super.key, required this.icon, this.size = 40});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Icon(icon, size: size * 0.55, color: colors.onPrimary),
    );
  }
}
