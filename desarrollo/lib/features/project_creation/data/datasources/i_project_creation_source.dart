import '../../domain/models/project_form_options.dart';

abstract class IProjectCreationSource {
  Future<ProjectFormOptions> getFormOptions();
}
