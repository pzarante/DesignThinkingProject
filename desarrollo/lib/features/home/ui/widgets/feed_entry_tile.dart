import 'package:flutter/material.dart';

import '../../../../core/widgets/app_icon_badge.dart';

/// Row used by the community, recommendation, and opportunity sections.
class FeedEntryTile extends StatelessWidget {
  const FeedEntryTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: AppIconBadge(icon: icon),
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle!),
        onTap: onTap,
      ),
    );
  }
}
