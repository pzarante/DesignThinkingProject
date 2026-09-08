import 'package:flutter/material.dart';

/// Circular avatar showing a person's initial when there is no real photo.
///
/// Used to represent users (creators, team members) — distinct from
/// [AppIconBadge], which represents system icons (bulb, calendar, etc.).
class AppAvatar extends StatelessWidget {
  const AppAvatar({super.key, required this.name, this.size = 40});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: colors.primaryContainer,
      child: Text(
        _initial,
        style: TextStyle(
          color: colors.onPrimaryContainer,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.4,
        ),
      ),
    );
  }

  String get _initial {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }
}
