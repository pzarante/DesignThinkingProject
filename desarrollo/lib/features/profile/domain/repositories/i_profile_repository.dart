import '../models/profile_project.dart';
import '../models/user_profile.dart';

abstract class IProfileRepository {
  Future<UserProfile?> getProfile(String userId);

  Future<List<UserSummary>> getUsers();

  Future<List<ProfileProject>> getProjectsOf(String userId);
}
