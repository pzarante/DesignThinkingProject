import '../../domain/models/profile_project.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/i_profile_repository.dart';
import '../datasources/i_profile_source.dart';

class ProfileRepository implements IProfileRepository {
  ProfileRepository(this.source);

  final IProfileSource source;

  @override
  Future<UserProfile?> getProfile(String userId) => source.getProfile(userId);

  @override
  Future<List<UserSummary>> getUsers() => source.getUsers();

  @override
  Future<List<ProfileProject>> getProjectsOf(String userId) =>
      source.getProjectsOf(userId);
}
