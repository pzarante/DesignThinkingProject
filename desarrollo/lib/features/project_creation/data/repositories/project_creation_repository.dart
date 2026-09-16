import '../../domain/models/project_form_options.dart';
import '../../domain/repositories/i_project_creation_repository.dart';
import '../datasources/i_project_creation_source.dart';

class ProjectCreationRepository implements IProjectCreationRepository {
  ProjectCreationRepository(this.source);

  final IProjectCreationSource source;

  @override
  Future<ProjectFormOptions> getFormOptions() async =>
      await source.getFormOptions();
}
