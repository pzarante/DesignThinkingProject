import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_choice_chip_row.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_search_bar.dart';
import '../../../../core/widgets/app_segmented_tab_bar.dart';
import '../../../notifications/ui/widgets/notifications_action.dart';
import '../../../profile/ui/viewmodels/user_search_controller.dart';
import '../../../profile/ui/widgets/user_result_tile.dart';
import '../viewmodels/home_controller.dart';
import '../widgets/project_card.dart';

/// Explorar: proyectos publicados y personas registradas.
///
/// Las dos pestañas comparten un solo buscador porque la intención es la
/// misma ("encontrar algo"); lo que cambia es contra qué se compara: el
/// nombre del proyecto o el `user_name` de la tabla `users`.
class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final HomeController _home = Get.find();
  final UserSearchController _people = Get.find();

  static const int _projectsTab = 0;
  static const List<String> _tabs = ['Proyectos', 'Personas'];

  int _tab = _projectsTab;

  /// El texto va a los dos controladores: cambiar de pestaña con algo escrito
  /// enseña el resultado de la otra lista en vez de un buscador en blanco.
  void _onQueryChanged(String value) {
    _home.setSearchQuery(value);
    _people.setQuery(value);
  }

  void _openDestination(int index) {
    final route = AppRoutes.mainDestinations[index];
    if (route == AppRoutes.explore) return;
    Get.offAllNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Explorar'),
        actions: const [NotificationsAction()],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Column(
              children: [
                AppSegmentedTabBar(
                  labels: _tabs,
                  selectedIndex: _tab,
                  onSelected: (index) => setState(() => _tab = index),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppSearchBar(
                  hintText: _tab == _projectsTab
                      ? 'Buscar proyectos...'
                      : 'Buscar por nombre de usuario...',
                  onChanged: _onQueryChanged,
                ),
              ],
            ),
          ),
          Expanded(
            child: _tab == _projectsTab
                ? const _ProjectResults()
                : const _PeopleResults(),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 1,
        onDestinationSelected: _openDestination,
      ),
    );
  }
}

/// Rejilla de proyectos con el filtro por categoría encima.
class _ProjectResults extends StatelessWidget {
  const _ProjectResults();

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.find();

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final query = controller.searchQuery.value.trim().toLowerCase();
      final tag = controller.selectedTag.value;
      final filtered = [
        ...controller.feed.recommendedProjects,
        ...controller.feed.myProjects,
      ].where((project) {
        final matchesQuery =
            query.isEmpty || project.name.toLowerCase().contains(query);
        final matchesTag = tag == null || project.tags.contains(tag);
        return matchesQuery && matchesTag;
      }).toList();

      final categoryOptions = ['Todos', ...controller.availableTags];

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: AppChoiceChipRow<String>(
              options: categoryOptions,
              labelBuilder: (option) => option == 'Todos' ? option : '#$option',
              selected: tag ?? 'Todos',
              onSelected: (option) =>
                  controller.setTag(option == 'Todos' ? null : option),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: AppEmptyState(
                      icon: Icons.travel_explore_outlined,
                      title: 'No se encontraron proyectos',
                      message: 'Prueba con otra palabra o quita el filtro de '
                          'categoría.',
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.scrollBottomInset,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: AppSpacing.sm,
                          mainAxisSpacing: AppSpacing.sm,
                          childAspectRatio: 0.72,
                        ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) =>
                        ProjectCard(project: filtered[index]),
                  ),
          ),
        ],
      );
    });
  }
}

/// Personas de la tabla `users`, buscadas por su `user_name`.
class _PeopleResults extends StatelessWidget {
  const _PeopleResults();

  @override
  Widget build(BuildContext context) {
    final UserSearchController controller = Get.find();

    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final error = controller.errorMessage.value;
      if (error != null) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AppEmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'No se pudieron cargar las personas',
            message: error,
            action: FilledButton.icon(
              onPressed: controller.load,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ),
        );
      }

      final results = controller.results;
      if (results.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AppEmptyState(
            icon: Icons.person_search_outlined,
            title: controller.query.value.trim().isEmpty
                ? 'Todavía no hay nadie registrado'
                : 'Nadie coincide con esa búsqueda',
            message: controller.query.value.trim().isEmpty
                ? 'Cuando se registren, aparecerán aquí.'
                : 'Revisa el nombre de usuario: se busca por @usuario.',
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.load,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.scrollBottomInset,
          ),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final user = results[index];
            return UserResultTile(
              user: user,
              onTap: () =>
                  Get.toNamed(AppRoutes.profile, arguments: user.userId),
            );
          },
        ),
      );
    });
  }
}
