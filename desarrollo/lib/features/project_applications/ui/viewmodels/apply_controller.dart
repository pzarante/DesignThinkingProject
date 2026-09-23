import 'package:get/get.dart';
import 'package:loggy/loggy.dart';

import '../../domain/models/project_application.dart';
import '../../domain/repositories/i_project_application_repository.dart';

class ApplyController extends GetxController with UiLoggy {
  ApplyController(this.repository);

  final IProjectApplicationRepository repository;

  final RxString motivation = ''.obs;
  final RxString availability = ''.obs;
  final RxnString desiredRole = RxnString();
  final RxBool isSubmitting = false.obs;
  final RxnString errorMessage = RxnString();

  /// True si este usuario ya tiene una postulación (de cualquier estado)
  /// para el proyecto que se está mirando.
  final RxBool alreadyApplied = false.obs;

  /// La postulación propia y pendiente cargada para editar/retirar, si hay.
  final Rxn<ProjectApplication> existing = Rxn<ProjectApplication>();

  Future<void> checkHasApplied({
    required String projectId,
    required String applicantId,
  }) async {
    alreadyApplied.value = await repository.hasApplied(
      projectId: projectId,
      applicantId: applicantId,
    );
  }

  /// Carga la postulación propia y pendiente para prellenar el formulario
  /// de edición desde el botón "Postulación pendiente".
  Future<void> loadOwn({
    required String projectId,
    required String applicantId,
  }) async {
    existing.value = await repository.getOwnApplication(
      projectId: projectId,
      applicantId: applicantId,
    );
  }

  bool get isValid =>
      motivation.value.trim().isNotEmpty &&
      availability.value.trim().isNotEmpty &&
      desiredRole.value != null;

  Future<bool> submit({
    required String projectId,
    required String applicantId,
    required String applicantName,
    required String applicantEmail,
  }) async {
    if (!isValid) {
      errorMessage.value = 'Elige un rol, tu disponibilidad y tu motivación.';
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
        roleTitle: desiredRole.value,
        createdAt: DateTime.now(),
      ),
    );

    alreadyApplied.value = true;

    loggy.debug('ApplyController: postulación enviada a $projectId');
    isSubmitting.value = false;
    return true;
  }

  /// Edita la postulación propia y pendiente ya cargada en [existing].
  Future<bool> saveEdits() async {
    final current = existing.value;
    if (current == null) return false;

    if (!isValid) {
      errorMessage.value = 'Elige un rol, tu disponibilidad y tu motivación.';
      return false;
    }

    isSubmitting.value = true;
    errorMessage.value = null;

    final updated = ProjectApplication(
      id: current.id,
      projectId: current.projectId,
      applicantId: current.applicantId,
      applicantName: current.applicantName,
      applicantEmail: current.applicantEmail,
      motivation: motivation.value.trim(),
      availability: availability.value.trim(),
      roleTitle: desiredRole.value,
      status: current.status,
      createdAt: current.createdAt,
    );

    await repository.update(updated);
    existing.value = updated;

    loggy.debug('ApplyController: postulación editada ${current.id}');
    isSubmitting.value = false;
    return true;
  }

  /// Retira la postulación propia y pendiente ya cargada en [existing].
  Future<void> withdraw() async {
    final current = existing.value;
    if (current == null) return;

    await repository.withdraw(current.id);
    existing.value = null;
    alreadyApplied.value = false;

    loggy.debug('ApplyController: postulación retirada ${current.id}');
  }
}
