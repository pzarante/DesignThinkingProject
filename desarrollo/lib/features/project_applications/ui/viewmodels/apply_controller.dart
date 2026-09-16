import 'package:get/get.dart';
import 'package:loggy/loggy.dart';

import '../../domain/models/project_application.dart';
import '../../domain/repositories/i_project_application_repository.dart';

class ApplyController extends GetxController with UiLoggy {
  ApplyController(this.repository);

  final IProjectApplicationRepository repository;

  final RxString motivation = ''.obs;
  final RxString availability = ''.obs;
  final RxBool isSubmitting = false.obs;
  final RxnString errorMessage = RxnString();

  /// True si este usuario ya tiene una postulación (de cualquier estado)
  /// para el proyecto que se está mirando. Se usa para no dejar postularse
  /// dos veces y para que el botón lo muestre antes de intentar enviar.
  final RxBool alreadyApplied = false.obs;

  Future<void> checkHasApplied({
    required String projectId,
    required String applicantId,
  }) async {
    alreadyApplied.value = await repository.hasApplied(
      projectId: projectId,
      applicantId: applicantId,
    );
  }

  bool get isValid =>
      motivation.value.trim().isNotEmpty &&
      availability.value.trim().isNotEmpty;

  Future<bool> submit({
    required String projectId,
    required String applicantId,
    required String applicantName,
    required String applicantEmail,
  }) async {
    if (!isValid) {
      errorMessage.value = 'Completa tu motivación y disponibilidad.';
      return false;
    }

    isSubmitting.value = true;
    errorMessage.value = null;

    final already = await repository.hasApplied(
      projectId: projectId,
      applicantId: applicantId,
    );
    if (already) {
      errorMessage.value = 'Ya enviaste una postulación a este proyecto.';
      isSubmitting.value = false;
      return false;
    }

    await repository.submit(
      ProjectApplication(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        projectId: projectId,
        applicantId: applicantId,
        applicantName: applicantName,
        applicantEmail: applicantEmail,
        motivation: motivation.value.trim(),
        availability: availability.value.trim(),
        createdAt: DateTime.now(),
      ),
    );

    alreadyApplied.value = true;

    loggy.debug('ApplyController: postulación enviada a $projectId');
    isSubmitting.value = false;
    return true;
  }
}
