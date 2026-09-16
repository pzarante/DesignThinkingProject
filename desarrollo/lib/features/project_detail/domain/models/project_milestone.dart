/// Estado de un paso del cronograma.
enum MilestoneStatus { completado, enProgreso, pendiente }

/// Paso del cronograma del proyecto.
class ProjectMilestone {
  const ProjectMilestone({
    required this.title,
    required this.status,
    this.dateLabel,
  });

  final String title;
  final MilestoneStatus status;

  /// Fecha tal como la muestra el diseño, p. ej. "Nov 2024".
  final String? dateLabel;

  String get statusLabel => switch (status) {
    MilestoneStatus.completado => 'Completado',
    MilestoneStatus.enProgreso => 'En progreso',
    MilestoneStatus.pendiente => 'Pendiente',
  };
}

/// Hito en curso con su porcentaje de avance.
class ActiveMilestone {
  const ActiveMilestone({required this.title, required this.progressPercent});

  final String title;
  final int progressPercent;
}
