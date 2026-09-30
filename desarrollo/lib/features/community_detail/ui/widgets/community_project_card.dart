import 'package:flutter/material.dart';

import '../../../home/domain/models/project.dart';
import '../../../home/ui/widgets/project_card.dart';
import '../../domain/models/community_detail.dart';

/// Un proyecto de la comunidad, con la misma tarjeta del feed.
///
/// La conversión a [Project] vive aquí, en la capa de UI: es la tarjeta la
/// que necesita ese tipo, tanto para dibujarse como para navegar al detalle.
class CommunityProjectCard extends StatelessWidget {
  const CommunityProjectCard({super.key, required this.project});

  final CommunityProject project;

  @override
  Widget build(BuildContext context) {
    return ProjectCard(
      project: Project(
        id: project.id,
        name: project.name,
        description: project.description,
        tags: project.tags,
        stage: project.stage,
        memberCount: project.memberCount,
        imageUrl: project.coverUrl,
        createdAt: project.createdAt,
      ),
    );
  }
}
