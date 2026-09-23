import 'package:get/get.dart';

import 'features/auth/ui/views/login_page.dart';
import 'features/auth/ui/views/signup_page.dart';
import 'features/community_creation/ui/views/community_created_page.dart';
import 'features/community_creation/ui/views/community_form_page.dart';
import 'features/creation/ui/views/create_entry_page.dart';
import 'features/home/ui/views/explore_page.dart';
import 'features/home/ui/views/home_page.dart';
import 'features/home/ui/views/my_projects_page.dart';
import 'features/project_detail/ui/views/project_detail_page.dart';
import 'features/project_detail/ui/views/project_settings_page.dart';
import 'features/project_creation/ui/views/project_created_page.dart';
import 'features/project_creation/ui/views/project_review_page.dart';
import 'features/project_creation/ui/views/project_wizard_page.dart';
import 'features/project_applications/ui/views/apply_page.dart';
import 'features/project_applications/ui/views/applicants_page.dart';

/// Named-route map for the top-level destinations of the app.
///
/// Only routes listed in [pages] can be pushed; [isRegistered] lets the
/// navigation bar tell an implemented destination from a planned one.
abstract final class AppRoutes {
  static const String home = '/home';
  static const String explore = '/explore';
  static const String myProjects = '/my-projects';
  static const String profile = '/profile';
  static const String projectDetail = '/project-detail';
  static const String applyToProject = '/apply';
  static const String projectApplicants = '/project-detail/applicants';

  /// Configuración del proyecto; solo la abre quien lo creó.
  static const String projectSettings = '/project-detail/settings';

  /// Bifurcación "¿Proyecto o Comunidad?" que abre el botón Crear.
  static const String create = '/create';
  static const String createProject = '/create/project';
  static const String createProjectReview = '/create/project/review';
  static const String createProjectSuccess = '/create/project/success';
  static const String createCommunity = '/create/community';
  static const String createCommunitySuccess = '/create/community/success';

  /// Inicio de sesión y registro; se llega aquí al intentar crear sin cuenta.
  static const String login = '/login';
  static const String signup = '/signup';

  /// Destination order shown by the bottom navigation bar.
  static const List<String> mainDestinations = [
    home,
    explore,
    myProjects,
    profile,
  ];

  static final List<GetPage> pages = [
    GetPage(name: home, page: () => const HomePage()),
    GetPage(name: explore, page: () => const ExplorePage()),
    GetPage(name: myProjects, page: () => const MyProjectsPage()),
    GetPage(name: projectDetail, page: () => const ProjectDetailPage()),
    GetPage(name: projectSettings, page: () => const ProjectSettingsPage()),
    GetPage(name: create, page: () => const CreateEntryPage()),
    GetPage(name: createProject, page: () => const ProjectWizardPage()),
    GetPage(name: createProjectReview, page: () => const ProjectReviewPage()),
    GetPage(name: createProjectSuccess, page: () => const ProjectCreatedPage()),
    GetPage(name: createCommunity, page: () => const CommunityFormPage()),
    GetPage(
      name: createCommunitySuccess,
      page: () => const CommunityCreatedPage(),
    ),
    GetPage(name: applyToProject, page: () => const ApplyPage()),
    GetPage(name: projectApplicants, page: () => const ApplicantsPage()),
    GetPage(name: login, page: () => const LoginPage()),
    GetPage(name: signup, page: () => const SignUpPage()),
  ];

  static bool isRegistered(String route) =>
      pages.any((page) => page.name == route);
}
