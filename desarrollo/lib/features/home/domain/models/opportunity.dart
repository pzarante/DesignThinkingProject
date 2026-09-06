class Opportunity {
  const Opportunity({
    required this.id,
    required this.name,
    this.participatingProjects = 0,
  });

  final String id;
  final String name;
  final int participatingProjects;
}
