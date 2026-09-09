import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_choice_chip_row.dart';
import '../../../../core/widgets/app_search_bar.dart';
import '../../../home/domain/models/project.dart';
import '../../../home/ui/viewmodels/home_controller.dart';
import '../../../home/ui/widgets/project_card.dart';

/// Explore screen — shows all projects (recommended + user's own) in a
/// two-column grid, with a search bar and tag-chip filter row.
class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeController ctrl = Get.find();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Explorar'),
      ),
      body: Obx(() {
        if (ctrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final allProjects = [
          ...ctrl.feed.recommendedProjects,
          ...ctrl.feed.myProjects,
        ];

        // Apply text search
        final query = ctrl.searchQuery.value.trim().toLowerCase();
        final tag = ctrl.selectedTag.value;

        final filtered = allProjects.where((p) {
          final matchesQuery =
              query.isEmpty || p.name.toLowerCase().contains(query);
          final matchesTag = tag == null || p.tags.contains(tag);
          return matchesQuery && matchesTag;
        }).toList();

        final categoryOptions = ['Todos', ...ctrl.availableTags];
        final selectedCategory = ctrl.selectedTag.value ?? 'Todos';

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              child: Column(
                children: [
                  AppSearchBar(
                    hintText: 'Buscar proyectos...',
                    onChanged: ctrl.setSearchQuery,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppChoiceChipRow<String>(
                    options: categoryOptions,
                    labelBuilder: (t) => t == 'Todos' ? t : '#$t',
                    selected: selectedCategory,
                    onSelected: (t) =>
                        ctrl.setTag(t == 'Todos' ? null : t),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No se encontraron proyectos.'))
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
                          _CompactProjectCard(project: filtered[index]),
                    ),
            ),
          ],
        );
      }),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 1,
        onDestinationSelected: (index) =>
            _openDestination(context, index),
      ),
    );
  }

  void _openDestination(BuildContext context, int index) {
    const destinations = ['/home', '/explore', '/my-projects', '/profile'];
    final route = destinations[index];
    if (route == '/explore') return;
    Get.offAllNamed(route);
  }
}

/// Compact version of [ProjectCard] sized for a 2-column grid.
class _CompactProjectCard extends StatelessWidget {
  const _CompactProjectCard({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ProjectCard(project: project);
  }
}
