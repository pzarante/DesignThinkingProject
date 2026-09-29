import 'package:flutter/material.dart';

import '../../../home/domain/models/project.dart';
import '../../../home/ui/widgets/project_card.dart';
import '../../domain/models/profile_project.dart';

/// Un proyecto del perfil con la misma tarjeta que usa el feed.
///
/// La conversión a [Project] vive aquí, en la capa de UI, para no atar el
/// dominio del perfil al de inicio: es la tarjeta la que necesita ese tipo,
/// tanto para dibujarse como para navegar al detalle.
class ProfileProjectCard extends StatelessWidget {
  const ProfileProjectCard({super.key, required this.project});

  final ProfileProject project;

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
