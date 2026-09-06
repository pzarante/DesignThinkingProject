import 'community.dart';
import 'opportunity.dart';
import 'project.dart';

/// Everything the home screen shows, resolved in a single read.
class HomeFeed {
  const HomeFeed({
    required this.followedCommunities,
    required this.recommendedProjects,
    required this.opportunities,
    required this.myProjects,
  });

  const HomeFeed.empty()
    : followedCommunities = const [],
      recommendedProjects = const [],
      opportunities = const [],
      myProjects = const [];

  final List<Community> followedCommunities;
  final List<Project> recommendedProjects;
  final List<Opportunity> opportunities;
  final List<Project> myProjects;
}
