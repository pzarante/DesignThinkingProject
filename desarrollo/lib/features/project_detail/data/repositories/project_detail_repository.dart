import '../../domain/models/project_comment.dart';
import '../../domain/models/project_detail.dart';
import '../../domain/models/project_member.dart';
import '../../domain/models/publication.dart';
import '../../domain/repositories/i_project_detail_repository.dart';
import '../datasources/i_project_detail_source.dart';

class ProjectDetailRepository implements IProjectDetailRepository {
  ProjectDetailRepository(this.source);

  final IProjectDetailSource source;

  @override
  Future<ProjectDetail?> getDetail(String projectId) async =>
      await source.getDetail(projectId);

  @override
  Future<void> saveDetail(
    ProjectDetail detail, {
    Set<String> originalMemberIds = const {},
  }) async =>
      await source.saveDetail(detail, originalMemberIds: originalMemberIds);

  @override
  Future<ProjectMember> getCurrentUser() async => await source.getCurrentUser();

  @override
  Future<void> addMember({
    required String projectId,
    required ProjectMember member,
    required String projectRoleId,
  }) async => await source.addMember(
    projectId: projectId,
    member: member,
    projectRoleId: projectRoleId,
  );

  @override
  Future<void> leaveProject({
    required String projectId,
    String? newLeaderId,
  }) async =>
      await source.leaveProject(projectId: projectId, newLeaderId: newLeaderId);

  @override
  Future<({int count, bool likedByMe})> getLikeStatus(String projectId) async =>
      await source.getLikeStatus(projectId);

  @override
  Future<int> toggleLike(String projectId) async =>
      await source.toggleLike(projectId);

  @override
  Future<({bool saved, bool following})> getViewerFlags(
    String projectId,
  ) async => await source.getViewerFlags(projectId);

  @override
  Future<bool> toggleSaved(String projectId) async =>
      await source.toggleSaved(projectId);

  @override
  Future<bool> toggleFollowing(String projectId) async =>
      await source.toggleFollowing(projectId);

  @override
  Future<List<ProjectComment>> getComments(String projectId) async =>
      await source.getComments(projectId);

  @override
  Future<ProjectComment> addComment(
    String projectId,
    String content, {
    String? authorName,
    String? publicationId,
  }) async => await source.addComment(
    projectId,
    content,
    authorName: authorName,
    publicationId: publicationId,
  );

  @override
  Future<List<Publication>> getPublications(String projectId) =>
      source.getPublications(projectId);

  @override
  Future<Publication> createPublication(Publication publication) =>
      source.createPublication(publication);

  @override
  Future<void> updatePublication(Publication publication) =>
      source.updatePublication(publication);

  @override
  Future<void> deletePublication(Publication publication) =>
      source.deletePublication(publication);

  @override
  Future<int> togglePublicationReaction(Publication publication) =>
      source.togglePublicationReaction(publication);

  @override
  Future<void> votePoll(Publication publication, String option) =>
      source.votePoll(publication, option);

  @override
  Future<void> deleteProject(String projectId) async =>
      await source.deleteProject(projectId);
}
