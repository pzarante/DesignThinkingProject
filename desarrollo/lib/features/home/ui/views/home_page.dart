import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_choice_chip_row.dart';
import '../../../../core/widgets/app_search_bar.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../viewmodels/home_controller.dart';
import '../widgets/feed_entry_tile.dart';
import '../widgets/project_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeController homeController = Get.find();

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 56,
        leading: const Padding(
          padding: EdgeInsets.only(left: AppSpacing.md),
          child: _AppLogo(),
        ),
        title: const Text('Innovation Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => _notifyPending(context),
          ),
        ],
      ),
      body: Obx(
        () => homeController.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: homeController.getFeed,
                child: _FeedList(controller: homeController),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _notifyPending(context),
        icon: const Icon(Icons.add),
        label: const Text('Crear'),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 0,
        onDestinationSelected: (index) => _openDestination(context, index),
      ),
    );
  }

  void _openDestination(BuildContext context, int index) {
    final route = AppRoutes.mainDestinations[index];
    if (route == AppRoutes.home) return;
    if (AppRoutes.isRegistered(route)) {
      Get.toNamed(route);
      return;
    }
    _notifyPending(context);
  }

  void _notifyPending(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Sección aún no disponible.')));
  }
}

class _AppLogo extends StatelessWidget {
  const _AppLogo();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset(
        'assets/launcher_icon/icon.png',
        width: 32,
        height: 32,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _FeedList extends StatelessWidget {
  const _FeedList({required this.controller});

  final HomeController controller;

  static const _typeLabels = {
    HomeEntryType.todos: 'Todos',
    HomeEntryType.proyectos: 'Proyectos',
    HomeEntryType.comunidades: 'Comunidades',
  };

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final feed = controller.feed;
      final categoryOptions = ['Todos', ...controller.availableTags];
      final selectedCategory = controller.selectedTag.value ?? 'Todos';

      return ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.scrollBottomInset,
        ),
        children: [
          AppSearchBar(
            hintText: 'Buscar proyectos, comunidades...',
            onChanged: controller.setSearchQuery,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppChoiceChipRow<HomeEntryType>(
            options: HomeEntryType.values,
            labelBuilder: (type) => _typeLabels[type]!,
            selected: controller.selectedType.value,
            onSelected: controller.setType,
          ),
          const SizedBox(height: AppSpacing.xs),
          AppChoiceChipRow<String>(
            options: categoryOptions,
            labelBuilder: (tag) => tag == 'Todos' ? tag : '#$tag',
            selected: selectedCategory,
            onSelected: (tag) => controller.setTag(tag == 'Todos' ? null : tag),
          ),
          const AppSectionHeader(title: 'Recomendado para ti'),
          for (final project in controller.filteredRecommendedProjects)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ProjectCard(project: project),
            ),
          const AppSectionHeader(title: 'Comunidades que sigues'),
          for (final community in controller.filteredCommunities)
            FeedEntryTile(
              icon: Icons.groups_outlined,
              title: community.name,
              subtitle: community.lastActivity,
            ),
          const AppSectionHeader(title: 'Mis Proyectos'),
          for (final project in controller.filteredMyProjectsSummary)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ProjectCard(project: project),
            ),
          const AppSectionHeader(title: 'Ferias y oportunidades'),
          for (final opportunity in feed.opportunities)
            FeedEntryTile(
              icon: Icons.calendar_today_outlined,
              title: opportunity.name,
              subtitle:
                  '${opportunity.participatingProjects} proyectos participando',
            ),
        ],
      );
    });
  }
}
