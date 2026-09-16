import '../models/community.dart';
import '../models/home_feed.dart';
import '../models/project.dart';

abstract class IHomeRepository {
  Future<HomeFeed> getFeed();

  Future<void> addProject(Project project);

  Future<void> addCommunity(Community community);

  Future<void> updateProject(Project project);
}
