import '../../domain/models/community.dart';
import '../../domain/models/home_feed.dart';
import '../../domain/models/project.dart';
import '../../domain/repositories/i_home_repository.dart';
import '../datasources/i_home_source.dart';

class HomeRepository implements IHomeRepository {
  HomeRepository(this.homeSource);

  final IHomeSource homeSource;

  @override
  Future<HomeFeed> getFeed() async => await homeSource.getFeed();

  @override
  Future<Project> addProject(
    Project project, {
    required String problem,
    required String objective,
    String? scope,
    required int maxMembers,
    required String availability,
  }) async => await homeSource.addProject(
    project,
    problem: problem,
    objective: objective,
    scope: scope,
    maxMembers: maxMembers,
    availability: availability,
  );

  @override
  Future<void> addCommunity(Community community) async =>
      await homeSource.addCommunity(community);

  @override
  Future<void> updateProject(Project project) async =>
      await homeSource.updateProject(project);
}
