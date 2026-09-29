import 'package:get/get.dart';
import 'package:loggy/loggy.dart';

import '../../../../core/error_message.dart' as errors;
import '../../../project_detail/domain/models/project_role.dart';
import '../../domain/models/project_application.dart';
import '../../domain/repositories/i_project_application_repository.dart';

/// Mensaje para mostrar. Las fuentes de datos lanzan [StateError] con un
/// texto ya pensado para quien usa la app ("Inicia sesión para…").
String _describe(Object exception) => exception is StateError
    ? exception.message
    : errors.errorMessage(exception);

class ApplyController extends GetxController with UiLoggy {
  ApplyController(this.repository);

  final IProjectApplicationRepository repository;

  final RxString motivation = ''.obs;
  final RxString availability = ''.obs;
  final Rxn<ProjectRole> desiredRole = Rxn<ProjectRole>();
  final RxBool isSubmitting = false.obs;
  final RxnString errorMessage = RxnString();

  /// True si este usuario tiene una postulación pendiente para el proyecto
  /// que se está mirando.
  final RxBool alreadyApplied = false.obs;

  /// La postulación propia y pendiente: la recién enviada, o la cargada para
  /// editar/retirar.
  final Rxn<ProjectApplication> existing = Rxn<ProjectApplication>();

  Future<void> checkHasApplied({
    required String projectId,
    required String applicantId,
  }) async {
    try {
      alreadyApplied.value = await repository.hasApplied(
        projectId: projectId,
        applicantId: applicantId,
      );
    } catch (exception) {
      // Sin poder saberlo se deja postular: el servidor sigue siendo quien
      // decide, y es mejor que bloquear el botón por un error de red.
      loggy.error('ApplyController: error checking application', exception);
      alreadyApplied.value = false;
    }
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

  /// Cupo concreto de `project_roles` al que apunta la postulación.
  ///
  /// Si se está editando y el rol no cambió, se conserva el cupo original
  /// aunque ya no aparezca libre: es el suyo.
  String _slotFor(ProjectRole role) {
    final current = existing.value;
    if (current != null &&
        (role.hasSlot(current.projectRoleId) ||
            role.title == current.roleTitle)) {
      return current.projectRoleId;
    }
    return role.firstOpenSlotId ?? role.title;
  }

  Future<bool> submit({
    required String projectId,
    required String applicantId,
    required String applicantName,
    required String applicantEmail,
  }) async {
    final role = desiredRole.value;
    if (!isValid || role == null) {
      errorMessage.value = 'Elige un rol, tu disponibilidad y tu motivación.';
      return false;
    }

    isSubmitting.value = true;
    errorMessage.value = null;
    try {
      final already = await repository.hasApplied(
        projectId: projectId,
        applicantId: applicantId,
      );
      if (already) {
        errorMessage.value = 'Ya tienes una postulación pendiente aquí.';
        return false;
      }

      existing.value = await repository.submit(
        ProjectApplication(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          projectId: projectId,
          projectRoleId: _slotFor(role),
          roleTitle: role.title,
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
      return true;
    } catch (exception) {
      loggy.error('ApplyController: error submitting', exception);
      errorMessage.value = _describe(exception);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Edita la postulación propia y pendiente ya cargada en [existing].
  Future<bool> saveEdits() async {
    final current = existing.value;
    final role = desiredRole.value;
    if (current == null) return false;

    if (!isValid || role == null) {
      errorMessage.value = 'Elige un rol, tu disponibilidad y tu motivación.';
      return false;
    }

    isSubmitting.value = true;
    errorMessage.value = null;
    try {
      final updated = current.copyWith(
        projectRoleId: _slotFor(role),
        roleTitle: role.title,
        motivation: motivation.value.trim(),
        availability: availability.value.trim(),
      );
      existing.value = await repository.update(updated);
      loggy.debug('ApplyController: postulación editada ${current.id}');
      return true;
    } catch (exception) {
      loggy.error('ApplyController: error editing', exception);
      errorMessage.value = _describe(exception);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Retira la postulación propia y pendiente ya cargada en [existing].
  Future<bool> withdraw() async {
    final current = existing.value;
    if (current == null) return false;

    isSubmitting.value = true;
    errorMessage.value = null;
    try {
      await repository.withdraw(current.id);
      existing.value = null;
      alreadyApplied.value = false;
      loggy.debug('ApplyController: postulación retirada ${current.id}');
      return true;
    } catch (exception) {
      loggy.error('ApplyController: error withdrawing', exception);
      errorMessage.value = _describe(exception);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }
}
