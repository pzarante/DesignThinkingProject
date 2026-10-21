import 'package:flutter/widgets.dart';

/// Keys de los widgets que recorren las pruebas de integración.
///
/// Viven en un solo sitio para que la pantalla y la prueba no se desincronicen:
/// renombrar una aquí rompe la compilación de las dos, no una prueba en
/// silencio. Buscar por key, y no por texto, es lo que deja cambiar un
/// rótulo sin tocar las pruebas.
abstract final class AppKeys {
  // Pantallas: van en el Scaffold de cada una.
  static const homePage = Key('HomePage');
  static const loginPage = Key('LoginPage');
  static const signUpPage = Key('SignUpPage');
  static const signUpSuccessPage = Key('SignUpSuccessPage');
  static const profilePage = Key('ProfilePage');
  static const myProjectsPage = Key('MyProjectsPage');
  static const createEntryPage = Key('CreateEntryPage');
  static const projectWizardPage = Key('ProjectWizardPage');
  static const projectReviewPage = Key('ProjectReviewPage');
  static const projectCreatedPage = Key('ProjectCreatedPage');
  static const projectDetailPage = Key('ProjectDetailPage');
  static const applicantsPage = Key('ApplicantsPage');
  static const communityFormPage = Key('CommunityFormPage');
  static const communityCreatedPage = Key('CommunityCreatedPage');

  // Barra inferior.
  static const navHome = Key('NavHome');
  static const navExplore = Key('NavExplore');
  static const navMyProjects = Key('NavMyProjects');
  static const navProfile = Key('NavProfile');

  // Inicio.
  static const homeCreateButton = Key('ButtonHomeCreate');
  static Key projectCard(String projectId) => Key('ProjectCard-$projectId');

  // ¿Proyecto o comunidad?
  static const createOptionProject = Key('OptionCreateProject');
  static const createOptionCommunity = Key('OptionCreateCommunity');
  static const createContinueButton = Key('ButtonCreateContinue');

  // Iniciar sesión.
  static const loginIdentifierField = Key('TextFieldLoginIdentifier');
  static const loginPasswordField = Key('TextFieldLoginPassword');
  static const loginSubmitButton = Key('ButtonLoginSubmit');
  static const loginGoToSignUpButton = Key('ButtonLoginCreateAccount');

  // Registro.
  static const signUpUserNameField = Key('TextFieldSignUpUserName');
  static const signUpEmailField = Key('TextFieldSignUpEmail');
  static const signUpPasswordField = Key('TextFieldSignUpPassword');

  /// "Continuar" en el primer paso y "Crear cuenta" en el segundo: es el
  /// mismo botón con otro rótulo.
  static const signUpSubmitButton = Key('ButtonSignUpSubmit');
  static const signUpErrorBanner = Key('SignUpErrorBanner');
  static const signUpSuccessHomeButton = Key('ButtonSignUpSuccessHome');
  static const signUpSuccessProfileButton = Key('ButtonSignUpSuccessProfile');

  // Perfil.
  static const profileLogoutButton = Key('ButtonProfileLogOut');
  static const profileLogoutConfirmButton = Key('ButtonProfileLogOutConfirm');
  static const profileLoginButton = Key('ButtonProfileLogin');

  // Asistente de proyecto.
  static Key stageOption(String stage) => Key('OptionStage-$stage');
  static const projectNameField = Key('TextFieldProjectName');
  static const projectDescriptionField = Key('TextFieldProjectDescription');
  static const projectProblemField = Key('TextFieldProjectProblem');
  static const projectObjectiveField = Key('TextFieldProjectObjective');

  /// "Siguiente" en los pasos 1 a 5 y "Revisar proyecto" en el último.
  static const wizardNextButton = Key('ButtonWizardNext');
  static const projectPublishButton = Key('ButtonProjectPublish');
  static const projectCreatedViewButton = Key('ButtonProjectCreatedView');

  // Detalle de proyecto.
  /// Crear publicación, Postularme o Postulación pendiente, según quién mira.
  static const projectDetailPrimaryButton = Key('ButtonProjectDetailPrimary');
  static const projectLeaveButton = Key('ButtonProjectLeave');
  static const projectLeaveConfirmButton = Key('ButtonProjectLeaveConfirm');
  static const projectApplicantsButton = Key('ButtonProjectApplicants');

  // Formulario de postulación.
  static const applicationRoleField = Key('DropdownApplicationRole');
  static const applicationMotivationField = Key('TextFieldApplicationMotivation');
  static const applicationSubmitButton = Key('ButtonApplicationSubmit');

  // Postulantes.
  static Key applicantAcceptButton(String applicationId) =>
      Key('ButtonApplicantAccept-$applicationId');
  static Key applicantRejectButton(String applicationId) =>
      Key('ButtonApplicantReject-$applicationId');

  // Comunidad.
  static const communityNameField = Key('TextFieldCommunityName');
  static const communityPickProjectsButton = Key('ButtonCommunityPickProjects');
  static const communityPickerConfirmButton = Key('ButtonCommunityPickerConfirm');
  static const communitySubmitButton = Key('ButtonCommunitySubmit');
  static const communityCreatedHomeButton = Key('ButtonCommunityCreatedHome');
}
