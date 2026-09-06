import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_icon_badge.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../auth/ui/viewmodels/authentication_controller.dart';
import '../../domain/models/home_feed.dart';
import '../../domain/models/project.dart';
import '../viewmodels/home_controller.dart';
import '../widgets/feed_entry_tile.dart';
import '../widgets/project_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeController homeController = Get.find();
    final AuthenticationController authenticationController = Get.find();

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 56,
        leading: const Padding(
          padding: EdgeInsets.only(left: AppSpacing.md),
          child: AppIconBadge(icon: Icons.lightbulb_outline, size: 32),
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
                child: _FeedList(
                  feed: homeController.feed,
                  greeting: Obx(
                    () => Text(
                      'Hola, ${authenticationController.loggedEmail}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ),
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sección aún no disponible.')),
    );
  }
}

class _FeedList extends StatelessWidget {
  const _FeedList({required this.feed, required this.greeting});

  final HomeFeed feed;
  final Widget greeting;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.scrollBottomInset,
      ),
      children: [
        greeting,
        const AppSectionHeader(title: 'Comunidades que sigues'),
        for (final community in feed.followedCommunities)
          FeedEntryTile(
            icon: Icons.groups_outlined,
            title: community.name,
          ),
        const AppSectionHeader(title: 'Recomendado para ti'),
        for (final project in feed.recommendedProjects)
          FeedEntryTile(
            icon: Icons.layers_outlined,
            title: project.name,
            subtitle: _projectLabels(project),
          ),
        const AppSectionHeader(title: 'Ferias y oportunidades'),
        for (final opportunity in feed.opportunities)
          FeedEntryTile(
            icon: Icons.calendar_today_outlined,
            title: opportunity.name,
            subtitle:
                '${opportunity.participatingProjects} proyectos participando',
          ),
        const AppSectionHeader(title: 'Mis Proyectos'),
        for (final project in feed.myProjects)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ProjectCard(project: project),
          ),
      ],
    );
  }

  String _projectLabels(Project project) => [
    ...project.tags,
    if (project.stage != null) project.stage!,
  ].join(' • ');
}
