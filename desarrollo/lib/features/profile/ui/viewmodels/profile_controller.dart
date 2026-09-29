import 'package:get/get.dart';
import 'package:loggy/loggy.dart';

// Con prefijo porque el campo reactivo `errorMessage` de este controlador
// taparía a la función del mismo nombre.
import '../../../../core/error_message.dart' as errors;
import '../../../auth/domain/repositories/i_auth_repository.dart';
import '../../domain/models/profile_project.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/i_profile_repository.dart';

/// Estado de la pantalla de perfil: la suya o la de otra persona.
///
/// Quién tiene la sesión abierta lo sigue llevando `AuthenticationController`;
/// aquí solo se le pregunta el identificador para saber qué perfil pedir.
class ProfileController extends GetxController with UiLoggy {
  ProfileController(this._repository, this._authRepository);

  final IProfileRepository _repository;
  final IAuthRepository _authRepository;

  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString();
  final Rxn<UserProfile> profile = Rxn<UserProfile>();
  final RxList<ProfileProject> projects = <ProfileProject>[].obs;

  /// False cuando se está mirando el perfil de otra persona: oculta cerrar
  /// sesión y cambia los textos de las listas vacías.
  final RxBool isOwnProfile = true.obs;

  /// True cuando no hay a quién enseñar: sin sesión, o como invitado, que es
  /// una cuenta de ROBLE sin fila en `users`.
  final RxBool needsAccount = false.obs;

  List<ProfileProject> get createdProjects =>
      projects.where((project) => project.isCreator).toList();

  List<ProfileProject> get joinedProjects =>
      projects.where((project) => !project.isCreator).toList();

  /// Carga un perfil. [userId] null es "el mío", que es como entra la pestaña
  /// de la barra inferior; con valor, es el de otra persona desde Explorar.
  Future<void> load({String? userId}) async {
    loggy.debug('ProfileController: loading profile ${userId ?? '(propio)'}');
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final me = await _authRepository.getLoggedUser();
      final myId = _authRepository.isAnonymous ? null : me?.id;
      final targetId = userId ?? myId;
      isOwnProfile.value = userId == null || userId == myId;

      if (targetId == null) {
        needsAccount.value = true;
        profile.value = null;
        projects.clear();
        return;
      }

      needsAccount.value = false;
      final loaded = await _repository.getProfile(targetId);
      profile.value = loaded;
      if (loaded == null) {
        projects.clear();
        errorMessage.value = isOwnProfile.value
            ? 'Tu cuenta todavía no tiene perfil. Vuelve a iniciar sesión '
                  'para crearlo.'
            : 'Esta persona todavía no tiene perfil.';
        return;
      }
      projects.assignAll(await _repository.getProjectsOf(targetId));
    } catch (exception, stackTrace) {
      loggy.error(
        'ProfileController: error loading profile',
        exception,
        stackTrace,
      );
      errorMessage.value = errors.errorMessage(exception);
    } finally {
      isLoading.value = false;
    }
  }

  /// Vuelve a pedirlo todo; lo usa el gesto de "deslizar para actualizar" y el
  /// regreso desde iniciar sesión.
  Future<void> refreshProfile() =>
      load(userId: isOwnProfile.value ? null : profile.value?.userId);
}
