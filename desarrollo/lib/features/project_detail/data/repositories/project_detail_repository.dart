import '../../domain/models/project_comment.dart';
import '../../domain/models/project_detail.dart';
import '../../domain/models/project_member.dart';
import '../../domain/repositories/i_project_detail_repository.dart';
import '../datasources/i_project_detail_source.dart';

class ProjectDetailRepository implements IProjectDetailRepository {
  ProjectDetailRepository(this.source);

  final IProjectDetailSource source;

  @override
  Future<ProjectDetail?> getDetail(String projectId) async =>
      await source.getDetail(projectId);

  @override
  Future<void> saveDetail(ProjectDetail detail) async =>
      await source.saveDetail(detail);

  @override
  Future<ProjectMember> getCurrentUser() async => await source.getCurrentUser();

  @override
  Future<({int count, bool likedByMe})> getLikeStatus(String projectId) async =>
      await source.getLikeStatus(projectId);

  @override
  Future<int> toggleLike(String projectId) async =>
      await source.toggleLike(projectId);

  @override
  Future<List<ProjectComment>> getComments(String projectId) async =>
      await source.getComments(projectId);

  @override
  Future<ProjectComment> addComment(String projectId, String content) async =>
      await source.addComment(projectId, content);
}
