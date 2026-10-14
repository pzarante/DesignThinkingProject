import 'package:get/get.dart';
import 'package:loggy/loggy.dart';

import '../../../../core/error_message.dart' as errors;
import '../../../project_detail/ui/viewmodels/project_detail_controller.dart';
import '../../domain/models/project_application.dart';
import '../../domain/repositories/i_project_application_repository.dart';

/// Mensaje para mostrar. Las fuentes de datos lanzan [StateError] con un
/// texto ya pensado para quien usa la app ("Inicia sesión para…").
String _describe(Object exception) => exception is StateError
    ? exception.message
    : errors.errorMessage(exception);

class ApplicantsController extends GetxController with UiLoggy {
  ApplicantsController(this.repository);

  final IProjectApplicationRepository repository;
  final RxList<ProjectApplication> applications = <ProjectApplication>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString();

  /// Postulación que se está aceptando o rechazando ahora mismo, para
  /// deshabilitar sus botones y mostrar que algo pasa.
  final RxnString processingId = RxnString();

  List<ProjectApplication> get pending => applications
      .where((a) => a.status == ProjectApplicationStatus.pending)
      .toList();

  Future<void> load(String projectId) async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      applications.assignAll(await repository.getForProject(projectId));
    } catch (exception) {
      loggy.error('ApplicantsController: error loading', exception);
      errorMessage.value = _describe(exception);
    } finally {
      isLoading.value = false;
    }
  }

  /// Acepta la postulación. Devuelve null si salió bien, o el mensaje de
  /// error para mostrar.
  ///
  /// Primero entra al equipo y después se marca como aceptada: si lo segundo
  /// falla, la persona ya es miembro y reintentar solo repite lo que falta.
  /// Al revés quedaría "aceptada" sin estar en el equipo.
  Future<String?> accept(ProjectApplication application) async {
    processingId.value = application.id;
    try {
      await Get.find<ProjectDetailController>().onApplicationAccepted(
        projectId: application.projectId,
        projectRoleId: application.projectRoleId,
        applicantId: application.applicantId,
        applicantName: application.applicantName,
        applicantEmail: application.applicantEmail,
        roleTitle: application.roleTitle ?? 'Rol no especificado',
        applicationId: application.id,
      );
      await repository.updateStatus(
        application.id,
        ProjectApplicationStatus.accepted,
      );
      return null;
    } catch (exception) {
      loggy.error('ApplicantsController: error accepting', exception);
      return _describe(exception);
    } finally {
      processingId.value = null;
      await load(application.projectId);
    }
  }

  /// Rechaza la postulación. Devuelve null si salió bien, o el mensaje de
  /// error para mostrar.
  Future<String?> reject(ProjectApplication application) async {
    processingId.value = application.id;
    try {
      await repository.updateStatus(
        application.id,
        ProjectApplicationStatus.rejected,
      );
      await Get.find<ProjectDetailController>().onApplicationRejected(
        projectId: application.projectId,
        applicantId: application.applicantId,
        applicationId: application.id,
      );
      return null;
    } catch (exception) {
      loggy.error('ApplicantsController: error rejecting', exception);
      return _describe(exception);
    } finally {
      processingId.value = null;
      await load(application.projectId);
    }
  }
}
