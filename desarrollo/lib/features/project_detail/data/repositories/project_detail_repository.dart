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
}
