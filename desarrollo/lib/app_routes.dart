import 'package:get/get.dart';

import 'features/home/ui/views/home_page.dart';

/// Named-route map for the top-level destinations of the app.
///
/// Only routes listed in [pages] can be pushed; [isRegistered] lets the
/// navigation bar tell an implemented destination from a planned one.
abstract final class AppRoutes {
  static const String home = '/home';
  static const String explore = '/explore';
  static const String myProjects = '/my-projects';
  static const String profile = '/profile';

  /// Destination order shown by the bottom navigation bar.
  static const List<String> mainDestinations = [
    home,
    explore,
    myProjects,
    profile,
  ];

  static final List<GetPage> pages = [
    GetPage(name: home, page: () => const HomePage()),
  ];

  static bool isRegistered(String route) =>
      pages.any((page) => page.name == route);
}
